require 'minitest/autorun'
require 'test_helper'

require 'json'
require 'tempfile'

require 'tt_extension_sources/model/version'

module TT::Plugins::ExtensionSources
  class VersionTest < Minitest::Test

    def test_class
      version = Version.new
      assert_kind_of(Comparable, version)
    end

    def test_initialize
      assert_equal([0, 0, 0], Version.new.to_a)
      assert_equal([1, 0, 0], Version.new(1).to_a)
      assert_equal([1, 2, 0], Version.new(1, 2).to_a)
      assert_equal([1, 2, 3], Version.new(1, 2, 3).to_a)
    end

    def test_initialize_argument_range
      assert_raises(RangeError) do
        Version.new(-1)
      end
      assert_raises(RangeError) do
        Version.new(1, -1)
      end
      assert_raises(RangeError) do
        Version.new(1, 2, -1)
      end
    end

    def test_parse
      assert_equal(Version.new(1, 2, 3), Version.parse('1.2.3'))
    end

    def test_compare_equal
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(1, 2, 3)
      assert_equal(0, version1 <=> version2)
    end

    def test_compare_larger_major
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(4, 2, 3)
      assert_equal(-1, version1 <=> version2)
    end

    def test_compare_larger_minor
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(1, 4, 3)
      assert_equal(-1, version1 <=> version2)
    end

    def test_compare_larger_patch
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(1, 2, 4)
      assert_equal(-1, version1 <=> version2)
    end

    def test_compare_smaller_major
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(0, 2, 3)
      assert_equal(1, version1 <=> version2)
    end

    def test_compare_smaller_minor
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(1, 0, 3)
      assert_equal(1, version1 <=> version2)
    end

    def test_compare_smaller_patch
      version1 = Version.new(1, 2, 3)
      version2 = Version.new(1, 2, 0)
      assert_equal(1, version1 <=> version2)
    end

    def test_compare_invalid_argument
      version = Version.new(1, 2, 3)
      assert_nil(version <=> 123)
    end

    def test_larger_than
      assert(Version.new(4, 2, 3) > Version.new(1, 2, 3))
      assert(Version.new(1, 4, 3) > Version.new(1, 2, 3))
      assert(Version.new(1, 2, 4) > Version.new(1, 2, 3))
    end

    def test_smaller_than
      assert(Version.new(0, 2, 3) < Version.new(1, 2, 3))
      assert(Version.new(1, 0, 3) < Version.new(1, 2, 3))
      assert(Version.new(1, 2, 0) < Version.new(1, 2, 3))
    end

    def test_equal
      assert(Version.new(1, 2, 3) == Version.new(1, 2, 3))
    end

    def test_compatible_with
      minimum = Version.new(1, 2, 3)
      assert(Version.new(1, 2, 3).compatible_with?(minimum))
      assert(Version.new(1, 2, 0).compatible_with?(minimum))
      assert(Version.new(1, 0, 3).compatible_with?(minimum))
      assert(Version.new(1, 0, 0).compatible_with?(minimum))
      assert(Version.new(0, 2, 3).compatible_with?(minimum))
      assert(Version.new(1, 2, 4).compatible_with?(minimum))
      assert(Version.new(1, 3, 3).compatible_with?(minimum))
      refute(Version.new(4, 2, 3).compatible_with?(minimum))
    end

    def test_to_a
      version = Version.new(1, 2, 3)
      result = version.to_a
      assert_kind_of(Array, result)
      assert_equal([1, 2, 3], result)
    end

    def test_to_s
      version = Version.new(1, 2, 3)
      result = version.to_s
      assert_kind_of(String, result)
      assert_equal('1.2.3', result)
    end

    def test_inspect
      version = Version.new(1, 2, 3)
      result = version.inspect
      assert_kind_of(String, result)
      assert_equal('#<ExtensionSources::Version 1.2.3>', result)
    end

    def test_as_json
      version = Version.new(1, 2, 3)
      result = version.as_json
      assert_kind_of(Array, result)
      assert_equal([1, 2, 3], result)
    end

    def test_to_json
      version = Version.new(1, 2, 3)
      result = version.to_json
      assert_kind_of(String, result)
      assert_equal('[1,2,3]', result)
    end

    def test_to_json_pretty_generate
      version = Version.new(1, 2, 3)
      result = JSON.pretty_generate(version)
      assert_kind_of(String, result)
      assert_equal("[\n  1,\n  2,\n  3\n]", result)
    end

  end # class
end # module
