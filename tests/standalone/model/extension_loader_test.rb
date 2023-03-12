require 'minitest/autorun'
require 'test_helper'
require 'test_system'

require 'json'
require 'tempfile'

require 'tt_extension_sources/model/extension_loader'
require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/model/statistics_csv'

module TT::Plugins::ExtensionSources
  class ExtensionLoaderTest < Minitest::Test

    def setup
      @system = TestSystem.new
      @statistics = TestStatistics.new # TODO:
      @sketchup = TestSketchUp.new(system: @system)
      @source = nil # TODO:

      # Make `TEST_SKETCHUP` available to the test files loaded.
      Object.const_set(:TEST_SKETCHUP, @sketchup)
    end

    def teardown
      Object.class_eval do
        remove_const(:TEST_SKETCHUP)
      end
    end


    def test_require_source_valid_measurement
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      loader.require_source(@source)

      assert_equal(1, loader.loaded_extensions.size)
      assert(loader.valid_measurement?)

      assert_equal(1, @statistics.size)
      assert_equal(source_path, @statistics.rows[0].path)
    end

    def test_require_source_too_many_extensions
      # TODO:
    end

    def test_require_source_too_few_extensions
      # TODO:
    end

    def test_require_source_load_errors
      # TODO:
    end

    def test_require_source_already_loaded
      # TODO:
    end

  end # class
end # module
