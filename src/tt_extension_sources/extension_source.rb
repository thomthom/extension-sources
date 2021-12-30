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
      @path_id = self.class.path_id(path)
      @path = path
      @enabled = enabled
    end

    # @return [String]
    def path_id
      @path_id
    end

    def path_exist?
      File.exist?(@path)
    end

    # @return [String]
    def path
      @path
    end

    # @param [String] value
    def path=(value)
      @path_id = self.class.path_id(value)
      @path = value
    end

    # @return [Boolean]
    def enabled?
      @enabled
    end

    # @param [Boolean] value
    def enabled=(value)
      @enabled = value
    end

    # @return [Hash]
    def to_hash
      {
        path_id: path_id,
        path_exist: path_exist?,
        path: path,
        enabled: enabled?,
      }
    end

    # @return [Hash]
    def serialize_as_hash
      {
        path: path,
        enabled: enabled?,
      }
    end

    # @return [Hash]
    def as_json(options={})
      # https://stackoverflow.com/a/40642530/486990
      to_hash
    end

    # @return [String]
    def to_json(*args)
      to_hash.to_json(*args)
    end

  end # class
end # module
