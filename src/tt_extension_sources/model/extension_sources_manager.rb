require 'fileutils'
require 'json'
require 'logger'
require 'observer'

require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/utils/inspection'
require 'tt_extension_sources/utils/timing'

module TT::Plugins::ExtensionSources
  # Raised when the given path already exists in the {ExtensionSourcesManager}.
  class PathNotUnique < StandardError; end

  # Manages the list of additional extension load-paths.
  class ExtensionSourcesManager

    include Inspection
    include Observable

    # @param [String] storage_path Full path to JSON file to serialize data to.
    # @param [Array] load_path
    # @param [Logger] logger
    def initialize(storage_path:, load_path: $LOAD_PATH, logger: Logger.new(nil), warnings: true)
      @warnings = warnings
      @logger = logger
      @load_path = load_path
      @storage_path = storage_path
      # TODO: Parse startup args:
      # "Config=${input:buildType};Path=${workspaceRoot}/ruby"
      #
      # Skip loading from paths in ARGV.
      #
      # "BootLoader=ExtensionSources;Config=${input:buildType};Path=${workspaceRoot}/ruby"
      @data = []
      deserialize
    end

    # @param [String] source_path
    # @return [ExtensionSource, nil]
    def add(source_path, enabled: true)
      warn "Path doesn't exist: #{source_path}" if @warnings && !File.exist?(source_path)

      return nil if include_path?(source_path)

      source = ExtensionSource.new(path: source_path, enabled: enabled)
      @data << source

      if source.enabled?
        add_load_path(source.path)
        require_sources(source.path)
      end

      source.add_observer(self, :on_source_changed)

      changed
      notify_observers(self, :added, source)

      source
    end

    # @param [Integer] source_id
    # @return [ExtensionSource, nil]
    def remove(source_id)
      source = find_by_source_id(source_id)
      raise IndexError, "source id #{source_id} not found" unless source

      @data.delete_if { |item| item.path == source.path }
      remove_load_path(source.path)

      source.delete_observer(self)

      changed
      notify_observers(self, :removed, source)

      source
    end

    # Updates properties of the given source path.
    #
    # @param [Integer] source_id
    # @param [String] path
    # @param [Boolean] enabled
    # @return [ExtensionSource]
    #
    # @raise [PathNotUnique] when the given path already exists in another
    #   {ExtensionSource} already added to the manager.
    def update(source_id:, path: nil, enabled: nil)
      source = find_by_source_id(source_id)
      raise IndexError, "source id #{source_id} not found" unless source

      if path && path != source.path
        raise PathNotUnique, "path '#{path}' already exists" if path && include_path?(path)
      end

      # Don't update if no properties changes value.
      return source if path.nil? && enabled.nil?

      if !enabled.nil? && enabled != source.enabled?
        source.enabled = enabled
        if source.enabled?
          add_load_path(source.path)
        else
          remove_load_path(source.path)
        end
      end

      if path && path != source.path
        remove_load_path(source.path)
        source.path = path
        if source.enabled?
          add_load_path(source.path)
          require_sources(source.path)
        end
      end

      source
    end

    # @param [String] export_path
    def export(export_path)
      data = serialize_as_hash
      json = JSON.pretty_generate(data)
      File.open(export_path, "w:UTF-8") do |file|
        file.write(json)
      end
      nil
    end

    # @param [String] import_path
    def import(import_path)
      json = File.open(import_path, "r:UTF-8", &:read)
      data = JSON.parse(json, symbolize_names: true)
      new_data = data.select { |item| !include_path?(item[:path]) }
      # First add all load paths, then require. This is to account for
      # extensions that depend on other extensions. These will assume the
      # dependent extension is present in the load path.
      timing = Timing.new
      timing.measure(label: 'Add load paths') do

        new_data.each { |item|
          add_load_path(item[:path]) if item[:enabled]
        }

      end
      timing.measure(label: 'Load extensions') do

        new_data.each { |item|
          add(item[:path], enabled: item[:enabled])
        }

      end
      @logger.info { "#{self.class.object_name} Loading extensions took:\n#{timing.format(prefix: '* ')}" }
      nil
    end

    # @param [Integer] source_id
    # @return [ExtensionSource]
    def find_by_source_id(source_id)
      @data.find { |source| source.source_id == source_id }
    end

    # @param [String] path
    # @return [ExtensionSource]
    def find_by_path(path)
      @data.find { |source| source.path == path }
    end

    # @param [String] path
    # @return [Boolean]
    def include_path?(path)
      !find_by_path(path).nil?
    end

    # @return [Array<ExtensionSource>]
    def sources
      @data
    end

    # @return [Hash]
    def as_json(options={})
      # https://stackoverflow.com/a/40642530/486990
      @data.map(&:to_hash)
    end

    # @return [String]
    def to_json(*args)
      @data.to_json(*args)
    end

    # Serializes the state of the extension manager.
    #
    # @return [nil]
    def save
      @logger.debug { "#{self.class.object_name} save" }
      serialize
      nil
    end

    # @param [ExtensionSource] source
    # @param [Symbol] event
    def on_source_changed(event, source)
      # @logger.debug { "#{self.class.object_name} on_source_changed: ##{source&.source_id}: #{source&.path}" }
      @logger.debug { "#{self.class.object_name} on_source_changed: ##{source ? source.source_id : nil}: #{source ? source.path : nil}" }
      changed
      notify_observers(self, :changed, source)
    end

    # @private
    # Data structure helper to aid in algorithmic processing of extension
    # sources.
    ItemState = Struct.new(:source, :index, :selected)
    private_constant :ItemState

    # Moves the given +sources+ in position at the target item.
    #
    # Either +before+ or +after+ must be provided as target item.
    #
    # @param [Array<ExtensionSource>] sources
    # @param [ExtensionSource, nil] before
    # @param [ExtensionSource, nil] after
    def move(sources:, before: nil, after: nil)
      raise ArgumentError, "Must use before: or after:" if before.nil? && after.nil?
      raise ArgumentError, "Must use either before: or after:, not both" if !before.nil? && !after.nil?

      target = before || after
      target_index = @data.find_index(target)
      raise "target not found: #{target.inspect}" if target_index.nil?

      target_index += 1 if after

      state = Hash[@data.map.with_index { |item, i|
        [item, ItemState.new(item, i, sources.include?(item))]
      }]
      # This is effectively performing a stable partition sort on the elements
      # above and below the target index.
      #
      # In C++ this would be done as:
      #   stable_partition(begin(xs), target, std::not_fn(pred));
      #   stable_partition(target, end(xs), pred);
      #
      # (See Sean Parent's talk: https://youtu.be/W2tWOdzgXHA?t=533)
      #
      # Ruby's Enumerable#partition doesn't do partial range, nor does it modify
      # the collection, instead it returns two new arrays. It's also not stable.
      #
      # When an array is returned to #sort_by it will sort by Array comparison.
      # This comparison is done by comparing each element in the array in
      # sequence.
      #
      # For this algorithm we first sort by the upper and lower set in the
      # collection, split by the insertion index. (primary)
      #
      # stable_partition [first, insert)
      # stable_partition [insert, last)
      #
      # Ruby Ranges:
      # (0..6) == [0..6]  <- inclusive last
      # (0...6) == [0..6) <- exclusive last
      #
      # Then, in the upper set the "selected" items should appear at the bottom
      # and in the lower set they should appear at the top. (secondary)
      #
      # In order to make this a stable sort, any equal comparison of the primary
      # and secondary values are resolved by the original index. (tertiary)
      upper = (0...target_index)
      @data.sort_by! { |source|
        item = state[source]
        in_upper = upper.include?(item.index)
        to_top_of_partition = if in_upper
          item.selected ? 1 : 0
        else
          item.selected ? 0 : 1
        end
        primary = in_upper ? 0 : 1
        secondary = to_top_of_partition
        tertiary = item.index
        [primary, secondary, tertiary]
      }

      changed
      notify_observers(self, :reordered)
      nil
    end

    private

    # @return [Hash]
    def serialize_as_hash
      @data.map(&:serialize_as_hash)
    end

    # @param [String] source_path
    # @return [Array<String>]
    def require_sources(source_path)
      pattern = "#{source_path}/*.rb"
      Dir.glob(pattern).each { |path|
        Sketchup.require(path)
      }.to_a
    end

    # @param [String] source_path
    # @return [Boolean]
    def add_load_path(source_path)
      return false if @load_path.include?(source_path)

      @load_path << source_path
      true
    end

    # @param [String] source_path
    # @return [Boolean]
    def remove_load_path(source_path)
      !@load_path.delete(source_path).nil?
    end

    # The absolute path where the manager will serialize to/from.
    #
    # @return [String]
    def storage_path
      @storage_path
    end

    # Serializes the state of the manager to {storage_path}.
    def serialize
      @logger.info { "#{self.class.object_name} serializing to '#{storage_path}'..." }
      directory = File.dirname(storage_path)
      unless File.directory?(directory)
        FileUtils.mkdir_p(directory)
      end
      warn "Storage directory missing: #{directory}" if @warnings && !File.directory?(directory)

      export(storage_path)
      @logger.info { "#{self.class.object_name} serializing done: #{storage_path}" }
    end

    # Deserializes the state of the manager from {storage_path}.
    def deserialize
      @logger.info { "#{self.class.object_name} deserializing from '#{storage_path}'..." }
      import(storage_path) if File.exist?(storage_path)
      @logger.info { "#{self.class.object_name} deserializing done: #{storage_path}" }
    end

  end # class
end # module
