require 'fileutils'
require 'json'
require 'logger'
require 'observer'

require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/inspection'

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

      # TODO: Account for enabled state.
      add_load_path(source.path)
      require_sources(source.path)

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

      # Don't update if no properties changes value.
      return source if path.nil? && enabled.nil?

      if (path && path != source.path)
        raise PathNotUnique, "path '#{path}' already exists" if path && include_path?(path)
      end

      remove_load_path(source.path) if path

      source.path = path unless path.nil?
      source.enabled = enabled unless enabled.nil?

      # TODO: Account for enabled state.
      add_load_path(source.path) if path
      require_sources(source.path) if path && source.enabled?

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
      # First add all load paths, then require. This is to account for
      # extensions that depend on other extensions. These will assume the
      # dependent extension is present in the load path.
      data.each { |item|
        add_load_path(item[:path])
      }
      data.each { |item|
        add(item[:path], enabled: item[:enabled])
      }
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
      @logger.debug { "#{self.class.object_name} on_source_changed: ##{source&.source_id}: #{source&.path}" }
      changed
      notify_observers(self, :changed, source)
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
      warn "Storage directory missing: #{directory}" if @warnings && File.directory?(directory)

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
