# ruby benchmarks\csv_write.rb
# ruby benchmarks\csv_write.rb ips

require_relative 'boot'

require 'csv'
require 'tempfile'

require 'tt_extension_sources/model/statistics_csv_file'

module TT::Plugins::ExtensionSources

  test_files_path = File.join(BenchmarkRunner::PROJECT_PATH, 'tests', 'standalone', 'model')
  csv_path = File.join(test_files_path, 'load-times.csv')
  statistics = StatisticsCSVFile.new(csv_path)
  data = statistics.read

  HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze

  puts "Number of records: #{data.size}"
  puts

  BenchmarkRunner.start do |x|

    x.report('Implemented') do
      tempfile = Tempfile.new('benchmark_csv_impl')
      tempfile.close
      stats = StatisticsCSVFile.new(tempfile.path)
      data.each { |record|
        stats.record(record)
      }
      tempfile.close
      tempfile.unlink
    end

    x.report('CSV Lib') do
      tempfile = Tempfile.new('benchmark_csv_lib')
      csv = CSV.new(tempfile,
        encoding: 'utf-8',
        headers: HEADERS,
        write_headers: true,
      )
      data.each { |record|
        csv << [
          record.sketchup,
          record.path,
          record.load_time,
          record.timestamp.iso8601
        ]
      }
      tempfile.close
      tempfile.unlink
    end

    x.report('CSV Lib (Seek)') do
      tempfile = Tempfile.new('benchmark_csv_lib_seek')
      csv = CSV.new(tempfile,
        encoding: 'utf-8',
        headers: HEADERS,
        write_headers: true,
      )
      data.each { |record|
        tempfile.seek(0, IO::SEEK_END)
        csv << [
          record.sketchup,
          record.path,
          record.load_time,
          record.timestamp.iso8601
        ]
      }
      tempfile.close
      tempfile.unlink
    end

    x.report('CSV Lib (Per Entry)') do
      tempfile = Tempfile.new('benchmark_csv_lib_per_entry')
      data.each { |record|
        csv = CSV.new(tempfile,
          encoding: 'utf-8',
          headers: HEADERS,
          write_headers: tempfile.size == 0,
        )
        tempfile.seek(0, IO::SEEK_END)
        csv << [
          record.sketchup,
          record.path,
          record.load_time,
          record.timestamp.iso8601
        ]
      }
      tempfile.close
      tempfile.unlink
    end

    x.report('Manual') do
      tempfile = Tempfile.new('benchmark_manual_csv')
      headers = HEADERS.join(',')
      data.each { |record|
        if tempfile.size == 0
          tempfile.puts(headers)
        end
        sketchup_version = record.sketchup
        path = record.path
        seconds = record.load_time
        timestamp = record.timestamp
        row = "#{sketchup_version},#{path},#{seconds},#{timestamp}"
        tempfile.puts(row)
      }
      tempfile.close
      tempfile.unlink
    end

    x.report('Manual (Reopen)') do
      tempfile = Tempfile.new('benchmark_manual_reopen_csv')
      tempfile.close
      headers = HEADERS.join(',')
      data.each { |record|
        tempfile.open
        if tempfile.size == 0
          tempfile.puts(headers)
        end
        sketchup_version = record.sketchup
        path = record.path
        seconds = record.load_time
        timestamp = record.timestamp
        row = "#{sketchup_version},#{path},#{seconds},#{timestamp}"
        tempfile.puts(row)
        tempfile.close
      }
      tempfile.unlink
    end

    x.report('Manual (Reopen File)') do
      tempfile = Tempfile.new('benchmark_manual_reopen_file_csv')
      tempfile.close
      headers = HEADERS.join(',')
      data.each { |record|
        File.open(tempfile.path, "a:UTF-8") { |file|
          if file.size == 0
            file.puts(headers)
          end
          sketchup_version = record.sketchup
          path = record.path
          seconds = record.load_time
          timestamp = record.timestamp
          row = "#{sketchup_version},#{path},#{seconds},#{timestamp}"
          file.puts(row)
        }
      }
      tempfile.unlink
    end

  end # benchmark

end # module
