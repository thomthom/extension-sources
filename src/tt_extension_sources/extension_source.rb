require 'json'
require 'observer'

module TT::Plugins::ExtensionSources
  class ExtensionSource

    # return [Integer]
    def self.generate_source_id
      @source_id ||= 0
      @source_id += 1
    end

    include Observable

    # A unique ID for this object. This differs from {Object#object_id} in that
    # the sequence is unique for this class and kept as small as possible.
    # @return [Numeric]
    attr_reader :source_id

    # @!attribute path
    # property :path

    # @!attribute [r] enabled?
    #   @return [Boolean]
    # @!attribute [w] enabled
    # property :enabled?

    # @param [String] path
    # @param [Boolean] enabled
    def initialize(path:, enabled: true)
      @source_id = self.class.generate_source_id
      @path = path
      @enabled = enabled
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
      return if value == @path

      @path = value
      changed
      notify_observers(:path, self)
    end

    # @return [Boolean]
    def enabled?
      @enabled
    end

    # @param [Boolean] value
    def enabled=(value)
      return if value == @enabled

      @enabled = value
      changed
      notify_observers(:enabled, self)
    end

    # @return [Hash]
    def to_hash
      {
        source_id: source_id,
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
    def as_json(options = {})
      # https://stackoverflow.com/a/40642530/486990
      to_hash
    end

    # @return [String]
    def to_json(*args)
      to_hash.to_json(*args)
    end

  end # class
end # module
