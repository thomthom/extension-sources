require 'minitest/autorun'
require 'test_helper'

require 'stringio'

require 'tt_extension_sources/model/statistics_csv'

module TT::Plugins::ExtensionSources
  class StatisticsCSVTest < Minitest::Test

    def test_read
      path = File.join(__dir__, 'load-times.csv')
      data = File.open(path) { |file|
        statistics = StatisticsCSV.new(io: file)
        statistics.read
      }
      assert_kind_of(Array, data)
      data.each { |row| assert_kind_of(Statistics::Record, row) }
      assert_equal(187, data.size)

      row = data.first

      assert_kind_of(String, row.sketchup)
      assert_equal('22.0.354', row.sketchup)

      assert_kind_of(String, row.path)
      assert_equal('C:/Users/Thomas/SourceTree/tt-library-2', row.path)

      assert_kind_of(Float, row.load_time)
      assert_equal(0.2650976, row.load_time)

      assert_kind_of(Time, row.timestamp)
      assert_equal(Time.iso8601('2022-11-07T18:15:41+01:00'), row.timestamp)
    end

    def test_read_multiple_times
      path = File.join(__dir__, 'load-times.csv')
      File.open(path) { |file|
        statistics = StatisticsCSV.new(io: file)

        data = statistics.read
        assert_kind_of(Array, data)
        assert_equal(187, data.size)

        data = statistics.read
        assert_kind_of(Array, data)
        assert_equal(187, data.size)
      }
    end

    def test_write
      io = StringIO.new
      statistics = StatisticsCSV.new(io: io)
      record = Statistics::Record.new(
        sketchup: '22.0.354',
        path: 'C:/Users/Thomas/SourceTree/tt-library-2',
        load_time: 0.2650976,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )
      statistics.record(record)
      refute_equal(0, io.size)
      # puts
      # puts io.string
      expected = <<-EOT.undent_heredoc
        SketchUp,Path,Load Time,Timestamp
        22.0.354,C:/Users/Thomas/SourceTree/tt-library-2,0.2650976,2022-11-07T18:15:41+01:00
      EOT
      assert_equal(expected, io.string)
    end

    def test_write_multiple
      io = StringIO.new
      record1 = Statistics::Record.new(
        sketchup: '22.0.354',
        path: 'C:/Users/Thomas/SourceTree/tt-library-2',
        load_time: 0.2650976,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )
      record2 = Statistics::Record.new(
        sketchup: '22.0.200',
        path: 'C:/Users/Thomas/SourceTree/TestUp2/src',
        load_time: 0.2772595,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )

      statistics = StatisticsCSV.new(io: io)
      statistics.record(record1)
      statistics.record(record2)

      expected = <<-EOT.undent_heredoc
        SketchUp,Path,Load Time,Timestamp
        22.0.354,C:/Users/Thomas/SourceTree/tt-library-2,0.2650976,2022-11-07T18:15:41+01:00
        22.0.200,C:/Users/Thomas/SourceTree/TestUp2/src,0.2772595,2022-11-07T18:15:41+01:00
      EOT
      assert_equal(expected, io.string)
    end

    def test_write_multiple_instances
      io = StringIO.new
      record1 = Statistics::Record.new(
        sketchup: '22.0.354',
        path: 'C:/Users/Thomas/SourceTree/tt-library-2',
        load_time: 0.2650976,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )
      record2 = Statistics::Record.new(
        sketchup: '22.0.200',
        path: 'C:/Users/Thomas/SourceTree/TestUp2/src',
        load_time: 0.2772595,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )

      statistics = StatisticsCSV.new(io: io)
      statistics.record(record1)

      statistics = StatisticsCSV.new(io: io)
      statistics.record(record2)

      expected = <<-EOT.undent_heredoc
        SketchUp,Path,Load Time,Timestamp
        22.0.354,C:/Users/Thomas/SourceTree/tt-library-2,0.2650976,2022-11-07T18:15:41+01:00
        22.0.200,C:/Users/Thomas/SourceTree/TestUp2/src,0.2772595,2022-11-07T18:15:41+01:00
      EOT
      assert_equal(expected, io.string)
    end

    def test_write_after_rewind
      io = StringIO.new
      record1 = Statistics::Record.new(
        sketchup: '22.0.354',
        path: 'C:/Users/Thomas/SourceTree/tt-library-2',
        load_time: 0.2650976,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )
      record2 = Statistics::Record.new(
        sketchup: '22.0.200',
        path: 'C:/Users/Thomas/SourceTree/TestUp2/src',
        load_time: 0.2772595,
        timestamp: Time.iso8601('2022-11-07T18:15:41+01:00'),
      )

      statistics = StatisticsCSV.new(io: io)
      statistics.record(record1)

      io.rewind

      statistics.record(record2)

      expected = <<-EOT.undent_heredoc
        SketchUp,Path,Load Time,Timestamp
        22.0.354,C:/Users/Thomas/SourceTree/tt-library-2,0.2650976,2022-11-07T18:15:41+01:00
        22.0.200,C:/Users/Thomas/SourceTree/TestUp2/src,0.2772595,2022-11-07T18:15:41+01:00
      EOT
      assert_equal(expected, io.string)
    end

  end # class
end # module