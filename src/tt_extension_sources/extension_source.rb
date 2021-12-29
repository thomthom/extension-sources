require 'json'

module TT::Plugins::ExtensionSources
  class ExtensionSource

    # @param [String] path
    # return [Integer]
    def self.path_id(path)
      path.hash
    end

    # @param [String] path
    # @param [Boolean] enabled
    def initialize(path:, enabled: true)
      @data = {
        path_id: self.class.path_id(path),
        path: path,
        enabled: enabled,
      }
    end

    # @return [String]
    def path_id
      @data[:path_id]
    end

    # @return [String]
    def path
      @data[:path]
    end

    # @param [String] value
    def path=(value)
      @data[:path_id] = self.class.path_id(value)
      @data[:path] = value
    end

    # @return [Boolean]
    def enabled?
      @data[:enabled]
    end

    # @param [Boolean] value
    def enabled=(value)
      @data[:enabled] = value
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
