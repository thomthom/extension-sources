# ruby profile_csv.rb > csv.html

require_relative 'boot'

require 'csv'
require 'tempfile'

require 'tt_extension_sources/model/statistics_csv'

module TT::Plugins::ExtensionSources

  test_files_path = File.join(ProfileRunner::PROJECT_PATH, 'tests', 'standalone', 'model')
  csv_path = File.join(test_files_path, 'load-times.csv')
  statistics = StatisticsCSV.new(io: File.open(csv_path, 'r'))
  data = statistics.read

  HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze

  puts "Number of records: #{data.size}"
  puts

  tempfile = Tempfile.new('benchmark_csv_impl')
  ProfileRunner.start do |x|

    stats = StatisticsCSV.new(io: tempfile)
    data.each { |record|
      stats.record(record)
    }

  end # profile
  tempfile.unlink

end # module
