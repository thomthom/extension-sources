# ruby profile_csv.rb > csv.html

require_relative 'boot'

require 'csv'
require 'tempfile'

require 'tt_extension_sources/model/statistics_csv_file'

module TT::Plugins::ExtensionSources

  test_files_path = File.join(ProfileRunner::PROJECT_PATH, 'tests', 'standalone', 'model')
  csv_path = File.join(test_files_path, 'load-times.csv')
  statistics = StatisticsCSVFile.new(csv_path)
  data = statistics.read

  HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze

  puts "Number of records: #{data.size}"
  puts

  ProfileRunner.start do |x|

    tempfile = Tempfile.new('benchmark_csv_impl')
    stats = StatisticsCSV.new(tempfile)
    data.each { |record|
      stats.record(record)
    }
    # tempfile.unlink

  end # profile

end # module
