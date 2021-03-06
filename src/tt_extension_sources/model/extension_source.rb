require 'json'
require 'observer'

module TT::Plugins::ExtensionSources
  # Represents an additional load-path from which to load source files from.
  class ExtensionSource

    # @return [Integer]
    def self.generate_source_id
      @source_id ||= 0
      @source_id += 1
    end

    include Observable

    # A unique ID for this object. This differs from `Object#object_id` in that
    # the sequence is unique for this class and kept as small as possible.
    #
    # The purpose is to be able to pass an ID to JavaScript (`UI::HtmlDialog`)
    # without generating potentially large integers that `Object#object_id` or
    # `String#hash` might do. These large integers would exceed the maximum safe
    # integer values of JavaScript and might loose precision. (You read that
    # correctly.)
    #
    # @return [Numeric]
    attr_reader :source_id

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

    # @return [String]
    def inspect(*args)
      hex_id = "0x%x" % (object_id << 1)
      %{#<ExtensionSource:#{hex_id} id=#{source_id.inspect} path=#{path.inspect} enabled=#{enabled?.inspect}>}
    end

  end # class
end # module
