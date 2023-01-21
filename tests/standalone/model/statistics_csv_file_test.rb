require 'minitest/autorun'
require 'test_helper'

require 'tt_extension_sources/model/statistics_csv_file'

module TT::Plugins::ExtensionSources
  class StatisticsCSVFileTest < Minitest::Test

    def test_read
      path = File.join(__dir__, 'load-times.csv')
      statistics = StatisticsCSVFile.new(path)
      data = statistics.read
      assert_kind_of(Array, data)
      data.each { |row| assert_kind_of(Statistics::Record, row) }
      assert_equal(187, data.size)
    end

    def test_write
      tempfile = Tempfile.new('test_csv_file')
      tempfile.close
      path = tempfile.path
      statistics = StatisticsCSVFile.new(path)
      record = Statistics::Record.new(
        sketchup: '22.0.354',
        path: 'C:/Users/Thomas/SourceTree/tt-library-2',
        load_time: 0.2650976,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )
      statistics.record(record)
      refute_equal(0, tempfile.size)
      expected = <<-EOT.undent_heredoc
        SketchUp,Path,Load Time,Timestamp
        22.0.354,C:/Users/Thomas/SourceTree/tt-library-2,0.2650976,2022-11-07T18:15:41+01:00
      EOT
      actual = tempfile.open.read
      assert_equal(expected, actual)
    end

  end # class
end # module
