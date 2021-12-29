require 'json'

require 'tt_extension_sources/extension_source'

module TT::Plugins::ExtensionSources
  class ExtensionSourcesManager

    def initialize
      @data = from_hash(dummy_extension_sources)
    end

    # @param [String] path
    # @return [ExtensionSource, nil]
    def add(path)
      return nil if include_path?(path)

      source = ExtensionSource.new(path: path)
      @data << source
      source
    end

    # @param [Integer] path_id
    # @return [ExtensionSource, nil]
    def remove(path_id)
      source = find_by_path_id(path_id)
      @data.delete(source)
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

      source.path = path unless path.nil?
      source.enabled = enabled unless enabled.nil?
      source
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
      to_hash
    end

    # @return [String]
    def to_json(*args)
      @data.to_json(*args)
    end

    private

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
