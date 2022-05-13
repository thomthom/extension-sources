require 'minitest/autorun'
require 'test_helper'

require 'faker'
require 'tempfile'

require 'tt_extension_sources/model/extension_source'

module TT::Plugins::ExtensionSources
  class ExtensionSourceTest < Minitest::Test

    # @param [#add_observer] observable
    # @param [Symbol] event
    # @param [Array] args
    # @return [Minitest::Mock]
    def assert_observer_event(observable, event, args, &block)
      mock = Minitest::Mock.new
      mock.expect(:hash, mock.object_id) # Because the observer is placed in a Hash as key.
      mock.expect(event, nil, args)
      observable.add_observer(mock, event)
      block.call
      mock.verify
      mock
    end


    def test_initialize_with_defaults
      path = Faker::File.dir
      source = ExtensionSource.new(path: path)
      assert_equal(path, source.path)
      assert_kind_of(TrueClass, source.enabled?)
      assert_kind_of(Integer, source.source_id)
    end

    def test_initialize_disabled
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: false)
      assert_equal(path, source.path)
      assert_kind_of(FalseClass, source.enabled?)
      assert_kind_of(Integer, source.source_id)
    end

    def test_initialize_unique_ids
      path = Faker::File.dir
      sources = 10.times.map {
        ExtensionSource.new(path: path)
      }
      ids = sources.map(&:source_id)
      assert_equal(ids.uniq, ids)
    end


    def test_path_exist_Query_with_fake_path
      path = Faker::File.dir
      source = ExtensionSource.new(path: path)
      assert_kind_of(FalseClass, source.path_exist?)
    end

    def test_path_exist_Query_with_real_path
      Tempfile.create('extension_source') do |file|
        source = ExtensionSource.new(path: file.path)
          assert_kind_of(TrueClass, source.path_exist?)
      end
    end


    def test_path
      path = Faker::File.dir
      source = ExtensionSource.new(path: path)
      assert_kind_of(String, source.path)
      assert_equal(path, source.path)
    end

    def test_path_Set
      path1 = Faker::File.unique.dir
      source = ExtensionSource.new(path: path1)
      path2 = Faker::File.unique.dir
      refute_equal(path1, path2)
      source.path = path2
      assert_equal(path2, source.path)
    end

    def test_path_Set_trigger_observer
      path = Faker::File.unique.dir
      source = ExtensionSource.new(path: path)
      assert_observer_event(source, :changed, [:path, source]) do
        source.path = Faker::File.unique.dir
      end
    end


    def test_enabled
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: true)
      assert_kind_of(TrueClass, source.enabled?)
      source.enabled = false
      assert_kind_of(FalseClass, source.enabled?)
      source.enabled = true
      assert_kind_of(TrueClass, source.enabled?)
    end

    def test_enabled_Set_trigger_observer
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: false)
      assert_observer_event(source, :changed, [:enabled, source]) do
        source.enabled = true
      end
    end


    def test_to_hash
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: false)
      result = source.to_hash
      assert_kind_of(Hash, result)
      expected = {
        source_id: source.source_id,
        path_exist: source.path_exist?,
        path: source.path,
        enabled: source.enabled?,
      }
      assert_equal(expected, result)
    end


    def test_serialize_as_hash
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: false)
      result = source.serialize_as_hash
      assert_kind_of(Hash, result)
      expected = {
        path: source.path,
        enabled: source.enabled?,
      }
      assert_equal(expected, result)
    end


    def test_as_json
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: false)
      result = source.as_json
      assert_kind_of(Hash, result)
      expected = {
        source_id: source.source_id,
        path_exist: source.path_exist?,
        path: source.path,
        enabled: source.enabled?,
      }
      assert_equal(expected, result)
    end


    def test_to_json
      path = Faker::File.dir
      source = ExtensionSource.new(path: path, enabled: false)
      result = source.to_json
      assert_kind_of(String, result)
      expected = {
        source_id: source.source_id,
        path_exist: source.path_exist?,
        path: source.path,
        enabled: source.enabled?,
      }
      assert_equal(expected.to_json, result)
    end

  end # class
end # module
