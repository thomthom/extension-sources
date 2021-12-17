require 'json'

module TT::Plugins::ExtensionSources
  class ExtensionSource

    attr_accessor :path, :enabled

    # @param [String] path
    # @param [Boolean] enabled
    def initialize(path:, enabled: true)
      @data = {
        path: path,
        enabled: enabled,
      }
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

  end # class
end # module
