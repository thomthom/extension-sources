# ruby profile_manual.rb > manual.html

require_relative 'boot'

require 'csv'
require 'tempfile'

require 'tt_extension_sources/model/statistics_csv_file'
require 'tt_extension_sources/model/statistics_csv_manual'

module TT::Plugins::ExtensionSources

  test_files_path = File.join(ProfileRunner::PROJECT_PATH, 'tests', 'standalone', 'model')
  csv_path = File.join(test_files_path, 'load-times.csv')
  statistics = StatisticsCSVFile.new(csv_path)
  data = statistics.read

  HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze

  puts "Number of records: #{data.size}"
  puts

  tempfile = Tempfile.new('benchmark_csv_impl')
  ProfileRunner.start do |x|

    headers = HEADERS.join(',')
    stats = StatisticsCSVManual.new(io: tempfile)
    data.each { |record|
      if tempfile.size == 0
        tempfile.puts(headers)
      else
        tempfile.seek(0, IO::SEEK_END)
      end
      sketchup_version = record.sketchup
      path = record.path
      seconds = record.load_time
      timestamp = record.timestamp
      row = "#{sketchup_version},#{path},#{seconds},#{timestamp}"
      tempfile.puts(row)
      tempfile.flush
    }

  end # profile
  tempfile.unlink

end # module
