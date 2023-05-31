require 'minitest/autorun'
require 'test_helper'

require 'json'

require 'tt_extension_sources/model/statistics_reporter'

module TT::Plugins::ExtensionSources
  class StatisticsReporterTest < Minitest::Test

    # @param [String] records_csv
    # @param [String] expected_json
    def compare_report_data(records_csv, expected_json, **report_options)
      records = File.open(records_csv) { |file|
        StatisticsCSV.new(io: file).read
      }

      stats = StatisticsReporter.new
      report = stats.report(records, **report_options)
      assert_kind_of(Hash, report)
      # puts
      # puts JSON.pretty_generate(report)
      # puts

      expected_path = expected_json
      expected = JSON.parse(File.read(expected_path))

      # Enable to regenerate expected JSON data:
      # File.write(expected_path, JSON.pretty_generate(report))

      expected.keys.each { |path|
        assert(report.key?(path), "expected: #{path}")

        expected_total = expected[path]['total'].transform_keys(&:to_sym)
        assert_equal(expected_total, report[path][:total])

        versions = expected[path]['versions']
        expected[path]['versions'].each { |version, data|
          assert(report[path][:versions].key?(version), "expected: #{path}:#{version}")

          expected_data = data.transform_keys(&:to_sym)
          assert_equal(expected_data, report[path][:versions][version])
        }
        assert_equal(versions.keys.sort, report[path][:versions].keys.sort)
      }
      assert_equal(expected.keys.sort, report.keys.sort)
    end

    def test_report_defaults
      records_path = File.join(__dir__, 'load-times.csv')
      expected_path = File.join(__dir__, 'load-times.json')
      compare_report_data(records_path, expected_path)
    end

    def test_report_group_by_major_minor_patch
      records_path = File.join(__dir__, 'load-times.csv')
      expected_path = File.join(__dir__, 'load-times_major-minor-patch.json')
      compare_report_data(records_path, expected_path,
        group_by: StatisticsReporter::GROUP_BY_MAJOR_MINOR_PATCH)
    end

    def test_report_group_by_major_minor
      records_path = File.join(__dir__, 'load-times.csv')
      expected_path = File.join(__dir__, 'load-times_major-minor.json')
      compare_report_data(records_path, expected_path,
        group_by: StatisticsReporter::GROUP_BY_MAJOR_MINOR)
    end

    def test_report_group_by_major
      records_path = File.join(__dir__, 'load-times.csv')
      expected_path = File.join(__dir__, 'load-times_major.json')
      compare_report_data(records_path, expected_path,
        group_by: StatisticsReporter::GROUP_BY_MAJOR)
    end

    def test_report_filter_major_minor
      records_path = File.join(__dir__, 'load-times_filter.csv')
      expected_path = File.join(__dir__, 'load-times_filter_major_minor.json')
      compare_report_data(records_path, expected_path, filters: ["21.1", "21.0"])
    end

  end # class
end # module
