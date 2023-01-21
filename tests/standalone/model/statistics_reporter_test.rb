require 'minitest/autorun'
require 'test_helper'

require 'json'

require 'tt_extension_sources/model/statistics_reporter'

module TT::Plugins::ExtensionSources
  class StatisticsReporterTest < Minitest::Test

    def test_report
      path = File.join(__dir__, 'load-times.csv')
      file = File.open(path)
      records = StatisticsCSV.new(file).read

      stats = StatisticsReporter.new
      report = stats.report(records)
      assert_kind_of(Hash, report)
      # puts
      # puts JSON.pretty_generate(report)
      # puts

      expected_path = File.join(__dir__, 'load-times.json')
      expected = JSON.parse(File.read(expected_path))

      expected.each { |path, versions|
        assert(report.key?(path), "expected: #{path}")

        versions.each { |version, data|
          assert(report[path].key?(version), "expected: #{path}:#{version}")

          expected_data = data.transform_keys(&:to_sym)
          # assert_kind_of(Statistics::Record, report[path][version])
          # assert_equal(expected_data, report[path][version].to_h)
          assert_equal(expected_data, report[path][version])
        }
        assert_equal(versions.keys.sort, report[path].keys.sort)
      }
      assert_equal(expected.keys.sort, report.keys.sort)
    rescue
      file.close
    end

  end # class
end # module
