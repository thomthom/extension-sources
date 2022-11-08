require 'minitest/autorun'
require 'test_helper'

require 'json'

require 'tt_extension_sources/model/statistics'

module TT::Plugins::ExtensionSources
  class StatisticsTest < Minitest::Test

    def test_report
      path = File.join(__dir__, 'load-times.csv')
      stats = Statistics.new(path: path)
      report = stats.report
      # puts
      # puts JSON.pretty_generate(report)
      # puts

      expected_path = File.join(__dir__, 'load-times.json')
      expected = JSON.load_file(expected_path)

      expected.each { |path, versions|
        assert(report.key?(path), "expected: #{path}")

        versions.each { |version, data|
          assert(report[path].key?(version), "expected: #{path}:#{version}")

          expected_data = data.transform_keys(&:to_sym)
          assert_equal(expected_data, report[path][version])
        }
        assert_equal(versions.keys.sort, report[path].keys.sort)
      }
      assert_equal(expected.keys.sort, report.keys.sort)
    end

  end # class
end # module
