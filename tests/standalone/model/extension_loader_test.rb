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

      # Because the fixtures require files we want to reset the list of loaded
      # features between each tests.
      @loaded_features = $LOADED_FEATURES.dup
      # Make `TEST_SKETCHUP` available to the test files loaded.
      Object.const_set(:TEST_SKETCHUP, @sketchup)
      # Make `TestExample` available with `TestExtension`.
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
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_too_few_extensions'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')

      assert_empty(loader.loaded_extensions, 'Extensions loaded')
      refute(loader.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
    end

    def test_require_source_load_errors_before_register_in_root
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_extension_root_error_before_register'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')

      assert_empty(loader.loaded_extensions, 'Extensions loaded')
      refute(loader.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
    end

    def test_require_source_load_errors_after_register_in_root
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_extension_root_error_after_register'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')

      assert_equal(1, loader.loaded_extensions.size, 'Extensions loaded')
      refute(loader.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
    end

    def test_require_source_load_errors_in_loader
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_extension_error_in_loader'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')

      assert_equal(1, loader.loaded_extensions.size, 'Extensions loaded')
      refute(loader.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
    end

    # TODO: Error in file required by loaded (Using Ruby require).

    # TODO: Error in file required by loaded (Using Sketchup.require).

    def test_require_source_already_loaded
      source = ExtensionSource.new(path: fixture('dummy_valid_extension'))

      loader1 = ExtensionLoader.new(
        system: @system,
        statistics: TestStatistics.new,
      )
      loader1.require_source(source)

      loader2 = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )
      files = loader2.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')

      assert_empty(loader2.loaded_extensions, 'Extensions loaded')
      refute(loader2.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
    end

    def test_require_source_load_errors_in_loader
      loader = ExtensionLoader.new(
        system: @system,
        statistics: @statistics,
      )

      source = ExtensionSource.new(path: fixture('dummy_extension_not_loading'))
      files = loader.require_source(source)

      assert_kind_of(Array, files)
      assert_equal(1, files.size, 'Files iterated')

      assert_equal(1, loader.loaded_extensions.size, 'Extensions loaded')
      refute(loader.valid_measurement?)

      assert_empty(@statistics.rows, 'Rows in stats')
    end

  end # class
end # module
