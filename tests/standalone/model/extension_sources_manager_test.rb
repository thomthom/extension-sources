require 'minitest/autorun'
require 'test_helper'

require 'json'
require 'tempfile'

require 'tt_extension_sources/model/extension_sources_manager'
require 'tt_extension_sources/model/extension_source'

module TT::Plugins::ExtensionSources
  class ExtensionSourcesManagerTest < Minitest::Test

    # Simulates default $LOAD_PATH items.
    FAKE_LOAD_PATH = [
      'fake/system/path/lib',
      'fake/system/path/gems',
      'fake/system/path/tools',
    ].freeze

    def setup
      @storage_path = Tempfile.new(['extension_sources', '.json'])
      @storage_path.write('[]')
      @storage_path.flush
      @load_path = FAKE_LOAD_PATH.dup
    end

    def teardown
      @storage_path.close(true)
    end


    # @param [Hash] data
    # @return [Tempfile]
    def write_storage_path_data(data = {}, &block)
      source_data = block_given? ? block.call : data
      json = JSON.pretty_generate(source_data)
      @storage_path.rewind
      @storage_path.write(json)
      @storage_path.flush
      source_data
    end


    # @param [#add_observer] observable
    # @param [Symbol] event
    # @param [Array] args
    # @return [Object]
    def assert_observer_event(observable, event, args, &block)
      mock = Minitest::Mock.new
      mock.expect(:hash, mock.object_id) # Because the observer is placed in a Hash as key.
      mock.expect(event, nil, args)
      observable.add_observer(mock, event)
      result = block.call
      assert_mock(mock)
      result
    end

    # @param [#add_observer] observable
    # @return [Object]
    def assert_no_observer_event(observable, &block)
      event = :changed
      mock = Minitest::Mock.new
      mock.expect(:hash, mock.object_id)
      mock.refuse(event)
      observable.add_observer(mock, event)
      result = block.call
      mock.verify
      result
    end

    # @param [Array<String>] load_path
    # @param [Array<String>] additional_paths Expected paths in addition to
    #   the default `FAKE_LOAD_PATH`.
    def assert_load_path(load_path, additional_paths)
      assert_equal(FAKE_LOAD_PATH.size + additional_paths.size, load_path.size)
      assert_equal(FAKE_LOAD_PATH + additional_paths, load_path)
    end


    def test_initialize_no_storage_path_file
      storage_path = '/fake/filename.json'
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: storage_path,
        warnings: false,
      )
      assert_empty(manager.sources)
      assert_load_path(@load_path, [])
    end

    def test_initialize_no_serialized_data
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      assert_empty(manager.sources)
      assert_load_path(@load_path, [])
    end

    def test_initialize_with_serialized_data
      data = write_storage_path_data do
        [
          {
            path: '/fake/path/hello',
            enabled: true,
          },
          {
            path: '/fake/path/world',
            enabled: false,
          },
        ]
      end

      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      enabled_data = data.select { |item| item[:enabled] }
      assert_load_path(@load_path, enabled_data.map { |item| item[:path]} )
      assert_equal(data, manager.sources.map(&:serialize_as_hash))
    end


    def test_add_enabled_path
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = assert_observer_event(manager, :changed, [manager, :added, ExtensionSource]) do
        manager.add(path, enabled: true)
      end
      assert_kind_of(TrueClass, source.enabled?)
      assert(manager.include_path?(path))
      assert(@load_path.include?(path))
    end

    def test_add_disabled_path
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = assert_observer_event(manager, :changed, [manager, :added, ExtensionSource]) do
        manager.add(path, enabled: false)
      end
      assert_kind_of(FalseClass, source.enabled?)
      assert(manager.include_path?(path))
      # Should not be in load path when source path is disabled.
      refute(@load_path.include?(path))
    end

    def test_add_default_enabled
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = assert_observer_event(manager, :changed, [manager, :added, ExtensionSource]) do
        manager.add(path)
      end
      assert_kind_of(TrueClass, source.enabled?)
      assert(manager.include_path?(path))
      assert(@load_path.include?(path))
    end


    def test_remove
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = manager.add(path, enabled: true)

      result = assert_observer_event(manager, :changed, [manager, :removed, ExtensionSource]) do
        manager.remove(source.source_id)
      end
      assert_equal(source, result)
      refute(manager.include_path?(path))
      refute(@load_path.include?(path))
    end

    def test_remove_invalid_source_id
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      manager.add(path, enabled: true)

      assert_raises(IndexError) do
        manager.remove(123456)
      end
    end


    def test_update_path
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path1 = '/fake/path/hello'
      source = manager.add(path1, enabled: true)

      path2 = '/fake/path/world'
      result = assert_observer_event(manager, :changed, [manager, :changed, ExtensionSource]) do
        manager.update(source_id: source.source_id, path: path2)
      end
      assert_equal(source, result)
      assert_equal(path2, source.path)
      refute(manager.include_path?(path1))
      assert(manager.include_path?(path2))
      refute(@load_path.include?(path1))
      assert(@load_path.include?(path2))
    end

    def test_update_enable_source
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = manager.add(path, enabled: false)

      result = assert_observer_event(manager, :changed, [manager, :changed, ExtensionSource]) do
        manager.update(source_id: source.source_id, enabled: true)
      end
      assert_equal(source, result)
      assert_kind_of(TrueClass, source.enabled?)
      assert(manager.include_path?(path))
      assert(@load_path.include?(path))
    end

    def test_update_disable_source
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = manager.add(path, enabled: true)

      result = assert_observer_event(manager, :changed, [manager, :changed, ExtensionSource]) do
        manager.update(source_id: source.source_id, enabled: false)
      end
      assert_equal(source, result)
      assert_kind_of(FalseClass, source.enabled?)
      assert(manager.include_path?(path))
      # Should not be in load path when source path is disabled.
      refute(@load_path.include?(path))
    end

    def test_update_nothing
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = manager.add(path, enabled: true)

      result = assert_no_observer_event(manager) do
        manager.update(source_id: source.source_id)
      end
      assert_equal(source, result)
      assert_kind_of(TrueClass, source.enabled?)
      assert(manager.include_path?(path))
      assert(@load_path.include?(path))
    end

    def test_update_enabled_no_change
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = manager.add(path, enabled: true)

      result = assert_no_observer_event(manager) do
        manager.update(source_id: source.source_id, enabled: true)
      end
      assert_equal(source, result)
      assert_kind_of(TrueClass, source.enabled?)
      assert(manager.include_path?(path))
      assert(@load_path.include?(path))
    end

    def test_update_path_no_change
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path = '/fake/path'
      source = manager.add(path, enabled: true)

      result = assert_no_observer_event(manager) do
        manager.update(source_id: source.source_id, path: path)
      end
      assert_equal(source, result)
      assert_equal(path, source.path)
      assert_kind_of(TrueClass, source.enabled?)
      assert(manager.include_path?(path))
      assert(@load_path.include?(path))
    end

    def test_update_path_already_exist
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      path1 = '/fake/path/hello'
      source1 = manager.add(path1, enabled: true)
      path2 = '/fake/path/world'
      source2 = manager.add(path2, enabled: true)

      assert_raises(PathNotUnique) do
        manager.update(source_id: source2.source_id, path: path1)
      end
      assert_equal(path1, source1.path)
      assert_equal(path2, source2.path)
      assert(manager.include_path?(path1))
      assert(manager.include_path?(path2))
      assert(@load_path.include?(path1))
      assert(@load_path.include?(path2))
    end


    def test_export
      export_path = Tempfile.new(['export', '.json'])

      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: false)
      manager.add('/fake/path/universe', enabled: true)

      expected = manager.sources.map(&:serialize_as_hash)
      assert_nil(manager.export(export_path))

      export_path.rewind
      json = export_path.read
      refute_empty(json)
      actual = JSON.parse(json, symbolize_names: true)
      assert_equal(expected, actual)
    ensure
      export_path.close(true)
    end


    def test_import
      import_path = Tempfile.new(['import', '.json'])

      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: false)
      original_data = manager.sources.map(&:serialize_as_hash)

      data = [
        {
          path: '/fake/path/mars',
          enabled: true,
        },
        {
          path: '/fake/path/venus',
          enabled: false,
        },
        {
          path: '/fake/path/jupiter',
          enabled: true,
        },
      ]
      # Add data for one original path. Ensure the state if different.
      original = original_data.last.dup
      original[:enabled] = !original[:enabled]
      data << original
      import_path.write(JSON.pretty_generate(data))
      import_path.flush

      mock = Minitest::Mock.new
      mock.expect(:hash, mock.object_id) # Because the observer is placed in a Hash as key.
      (data.size - 1).times {
        args = [ExtensionSourcesManager, :added, ExtensionSource]
        mock.expect(:changed, nil, args)
      }
      manager.add_observer(mock, :changed)

      assert_nil(manager.import(import_path.path))
      assert_equal(original_data.size + data.size - 1, manager.sources.size)
      original_data.each { |item|
        assert(manager.include_path?(item[:path]), item)
        assert_equal(item[:enabled], @load_path.include?(item[:path]), item)
      }
      data.each { |item|
        assert(manager.include_path?(item[:path]), item)
        # This line is to account for the overlapping item. The original value
        # should be preserved over the imported value.
        expected = (item[:path] == original[:path]) ? !item[:enabled] : item[:enabled]
        assert_equal(expected, @load_path.include?(item[:path]), item)
      }
      assert_mock(mock)
    ensure
      import_path.close(true)
    end


    def test_find_by_source_id_valid_id
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      source1 = manager.add('/fake/path/hello', enabled: true)
      source2 = manager.add('/fake/path/world', enabled: true)

      result = manager.find_by_source_id(source2.source_id)
      refute_equal(source1, result)
      assert_equal(source2, result)
    end

    def test_find_by_source_id_not_found
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: true)

      result = manager.find_by_source_id(123456)
      assert_nil(result)
    end


    def test_find_by_path_valid_path
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      source1 = manager.add('/fake/path/hello', enabled: true)
      source2 = manager.add('/fake/path/world', enabled: true)

      result = manager.find_by_path(source2.path)
      refute_equal(source1, result)
      assert_equal(source2, result)
    end

    def test_find_by_path_not_found
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: true)

      result = manager.find_by_path('/fake/path/universe')
      assert_nil(result)
    end


    def test_include_path
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      source1 = manager.add('/fake/path/hello', enabled: true)
      source2 = manager.add('/fake/path/world', enabled: true)

      assert_kind_of(TrueClass, manager.include_path?(source1.path))
      assert_kind_of(TrueClass, manager.include_path?(source2.path))
    end

    def test_include_path_not_added
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: true)

      assert_kind_of(FalseClass, manager.include_path?('/fake/path/universe'))
    end


    def test_sources
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      source1 = manager.add('/fake/path/hello', enabled: true)
      source2 = manager.add('/fake/path/world', enabled: true)

      result = manager.sources
      assert_kind_of(Array, result)
      result.each { |item|
        assert_kind_of(ExtensionSource, item)
      }
      expected = [source1, source2]
      assert_equal(expected, result)
    end


    def test_as_json
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      source1 = manager.add('/fake/path/hello', enabled: true)
      source2 = manager.add('/fake/path/world', enabled: true)

      result = manager.as_json
      assert_kind_of(Array, result)
      result.each { |item|
        assert_kind_of(Hash, item)
      }
      expected = [source1, source2].map(&:to_hash)
      assert_equal(expected, result)
    end


    def test_to_json
      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: true)

      result = manager.to_json
      assert_kind_of(String, result)
      expected = manager.as_json.to_json
      assert_equal(expected, result)
    end


    def test_save
      assert_equal(2, @storage_path.size)

      manager = ExtensionSourcesManager.new(
        load_path: @load_path,
        storage_path: @storage_path.path,
        warnings: false,
      )
      manager.add('/fake/path/hello', enabled: true)
      manager.add('/fake/path/world', enabled: true)
      assert_equal(2, @storage_path.size)

      manager.save
      assert(@storage_path.size > 2)

      @storage_path.rewind
      json = @storage_path.read
      data = JSON.parse(json, symbolize_names: true)
      assert_equal(manager.sources.size, data.size)
      expected = manager.sources.map(&:serialize_as_hash)
      assert_equal(expected, data)
    end

  end # class
end # module
