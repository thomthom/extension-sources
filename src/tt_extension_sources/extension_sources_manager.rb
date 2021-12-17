require 'json'

require 'tt_extension_sources/extension_source'

module TT::Plugins::ExtensionSources
  class ExtensionSourcesManager

    def initialize
      @data = from_hash(dummy_extension_sources)
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
      ]
    end

  end # class
end # module
