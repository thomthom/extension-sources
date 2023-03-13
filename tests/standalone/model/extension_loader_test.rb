require 'minitest/autorun'
require 'fixtures'
require 'test_helper'
require 'test_system'

require 'json'
require 'tempfile'

require 'tt_extension_sources/model/extension_loader'
require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/model/statistics_csv'

module TT::Plugins::ExtensionSources
  class ExtensionLoaderTest < Minitest::Test

    include ExtensionSourcesFixtures

    def setup
      @system = TestSystem.new
      @statistics = TestStatistics.new
      @sketchup = TestSketchUp.new(system: @system)

      @loaded_features = $LOADED_FEATURES.dup
      # Make `TEST_SKETCHUP` available to the test files loaded.
      Object.const_set(:TEST_SKETCHUP, @sketchup)
      Object.const_set(:TestExample, Module.new)
      Object::TestExample.const_set(:TestExtension, TT::Plugins::ExtensionSources::TestExtension)
    end

    def teardown
      $LOADED_FEATURES.delete_if { |feature| @loaded_features.include?(feature) }
      Object.class_eval do
        remove_const(:TEST_SKETCHUP)
        # The fixtures uses a TestExample module to sandbox the test logic.
        remove_const(:TestExample) if const_defined?(:TestExample)
      end
    end


    def test_require_source_valid_measurement
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_valid_extension'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')
      assert_equal(File.join(source.path, 'dummy_valid_extension.rb'), files[0])

      assert_equal(1, loader.loaded_extensions.size, 'Extensions loaded')
      assert(loader.valid_measurement?)

      assert_equal(1, @statistics.rows.size, 'Rows in stats')
      assert_equal(source.path, @statistics.rows[0].path)
    end

    def test_require_source_too_many_extensions
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_two_valid_extensions'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(2, files.size, 'Files iterated')

      assert_equal(2, loader.loaded_extensions.size, 'Extensions loaded')
      refute(loader.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
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
