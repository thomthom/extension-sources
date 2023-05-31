module TT::Plugins::ExtensionSources
  # Represents semantic version.
  class Version

    include Comparable

    attr_accessor :major, :minor, :patch

    # @param [String] version_string
    def self.parse(version_string)
      components = version_string.split('.').map(&:to_i)
      self.new(*components)
    end

    # @param [Integer] major
    # @param [Integer] minor
    # @param [Integer] patch
    def initialize(major = 0, minor = 0, patch = 0)
      @major = check_argument(major)
      @minor = check_argument(minor)
      @patch = check_argument(patch)
    end

    # @param [Version] other
    # @return [Integer, nil]
    def <=>(other)
      return nil unless other.is_a?(Version)

      x = @major <=> other.major
      return x unless x == 0

      y = @minor <=> other.minor
      return y unless y == 0

      @patch <=> other.patch
    end

    # Checks if this version is semantically compatible with the other version.
    # This will only return `false` if this version's major component is larger
    # than the other version's.
    #
    # @param [Version] version
    def compatible_with?(version)
      return version.major >= @major
    end

    # @param [String] version_string
    def match?(version_string)
      components = version_string.split('.').map(&:to_i)
      components.each { |n| check_argument(n) }

      to_a.take(components.size) == components
    end

    # @return [Array(Integer, Integer, Integer)]
    def to_a
      [major, minor, patch]
    end

    # @return [String]
    def to_s
      "#{major}.#{minor}.#{patch}"
    end

    # @return [String]
    def inspect(*args)
      "#<ExtensionSources::Version #{to_s}>"
    end

    # @param [Hash] options
    # @return [Array]
    def as_json(**options)
      to_a
    end

    # @param [Array] args
    # @return [Array]
    def to_json(*args)
      as_json.to_json(*args)
    end

    private

    # @param [Object] argument
    def check_argument(argument)
      unless argument.is_a?(Integer)
        raise TypeError, "expected Integer, got #{argument.class}"
      end
      if argument < 0
        raise RangeError, "version component cannot be negative, got #{argument}"
      end
      argument
    end

  end # class
end # module
