# ruby benchmarks\csv_write.rb
# ruby benchmarks\csv_write.rb ips

require_relative 'boot'

require 'tempfile'

require 'tt_extension_sources/model/statistics_csv_file'

module TT::Plugins::ExtensionSources

  test_files_path = File.join(BenchmarkRunner::PROJECT_PATH, 'tests', 'standalone', 'model')
  csv_path = File.join(test_files_path, 'load-times.csv')
  statistics = StatisticsCSVFile.new(csv_path)
  data = statistics.read

  puts "Number of records: #{data.size}"
  puts

  BenchmarkRunner.start do |x|

    x.report('CSV Lib') do
      tempfile = Tempfile.new('benchmark_csv_lib')
      tempfile.close
      stats = StatisticsCSVFile.new(tempfile.path)
      data.each { |record|
        stats.record(record)
      }
    end

    # TODO: Add report for CSV directly. (duplicate CVS logic)
    # TODO: Rename 'CSV Lib' report to 'StatisticsCSVFile'

    x.report('Manual') do
      tempfile = Tempfile.new('benchmark_manual_csv')
      data.each { |record|
        if tempfile.size == 0
          header = 'SketchUp,Path,Load Time,Timestamp'
          tempfile.puts(header)
        end
        sketchup_version = record.sketchup
        path = record.path
        seconds = record.load_time
        timestamp = record.timestamp
        row = "#{sketchup_version},#{path},#{seconds},#{timestamp}"
        tempfile.puts(row)
      }
    end

  end # benchmark

end # module
