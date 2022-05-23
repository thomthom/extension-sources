require 'minitest/autorun'
require 'fixtures'
require 'test_helper'

require 'tt_extension_sources/model/extension_sources_scanner'

module TT::Plugins::ExtensionSources
  class ScanExtensionSourcesTest < Minitest::Test

    include ExtensionSourcesFixtures

    def test_scan
      scanner = ExtensionSourcesScanner.new
      result = scanner.scan(fixtures_path)
      assert_kind_of(Array, result)
      refute_empty(result)
      result.each { |item| assert_kind_of(String, item) }
      expected = %w[
        nested/with_register_extension
        nested_with_multiple_register_extension
        with_multiple_register_extension
        with_register_extension
      ].map { |item| File.join(fixtures_path, item) }
      assert_equal(expected.sort, result.sort)
    end

  end # class
end # module
