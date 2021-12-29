require 'json'

require 'tt_extension_sources/extension_source'

module TT::Plugins::ExtensionSources
  class ExtensionSourcesManager

    def initialize
      @data = from_hash(dummy_extension_sources)
    end

    # @param [String] source_path
    # @return [ExtensionSource, nil]
    def add(source_path, enabled: true)
      raise "Path doesn't exist: #{source_path}" unless File.exist?(source_path)

      return nil if include_path?(source_path)

      source = ExtensionSource.new(path: source_path, enabled: enabled)
      @data << source

      # TODO: Account for enabled state.
      add_load_path(source.path)
      require_sources(source.path)

      source
    end

    # @param [Integer] path_id
    # @return [ExtensionSource, nil]
    def remove(path_id)
      source = find_by_path_id(path_id)
      raise IndexError, "source path id #{path_id} not found" unless source

      @data.delete_if { |item| item.path == source.path }
      remove_load_path(source.path)

      source
    end

    # @param [Integer] path_id
    # @param [String] path
    # @param [Boolean] enabled
    # @return [ExtensionSource]
    def update(path_id:, path: nil, enabled: nil)
      source = find_by_path_id(path_id)
      raise IndexError, "source path id #{path_id} not found" unless source

      # TODO: Use custom errors.
      raise "path '#{path}' already exists" if path && include_path?(path)

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
      data = as_json
      data.each { |path| path.delete(:path_id) }
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
      data.each { |item|
        unless File.exist?(item[:path])
          # TODO: Still display paths not found?
          warn "Path not found: #{item[:path]}"
          next
        end

        source = add(item[:path], enabled: item[:enabled])
      }
      nil
    end

    # @param [Integer] path_id
    # @return [ExtensionSource]
    def find_by_path_id(path_id)
      @data.find { |source| source.path_id == path_id }
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
    def to_hash
      @data.dup
    end

    # @return [Hash]
    def as_json(options={})
      # https://stackoverflow.com/a/40642530/486990
      to_hash.map(&:to_hash)
    end

    # @return [String]
    def to_json(*args)
      @data.to_json(*args)
    end

    private

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
      return false if $LOAD_PATH.include?(source_path)

      $LOAD_PATH << source_path
      true
    end

    # @param [String] source
    # @return [Boolean]
    def remove_load_path(source_path)
      !$LOAD_PATH.delete(source_path).nil?
    end

    # @param [Array<Hash>] data
    # @return [Array<ExtensionSource>]
    def from_hash(data)
      data.map { |hash| ExtensionSource.new(**hash) }
    end

    # @return [Array<Hash>]
    def dummy_extension_sources
      [
        {
          path: 'C:/Users/Thomas/SourceTree/TrueBend/src',
          enabled: true,
        },
        {
          path: 'C:/Users/Thomas/SourceTree/CleanUp/src',
          enabled: false,
        },
        {
          path: 'C:/Users/Thomas/SourceTree/SolidInspector/src',
          enabled: true,
        },
        {
          path: 'C:/Users/Thomas/SourceTree/quadface-tools/src',
          enabled: true,
        },
        {
          path: 'C:/Users/Thomas/SourceTree/SpeedUp/src',
          enabled: false,
        },
        {
          path: 'C:/Users/Thomas/SourceTree/architect-tools/src',
          enabled: true,
        },
      ]
    end

  end # class
end # module
