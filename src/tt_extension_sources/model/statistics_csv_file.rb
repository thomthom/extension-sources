require 'tt_extension_sources/model/statistics'
require 'tt_extension_sources/model/statistics_csv'

module TT::Plugins::ExtensionSources
  # Serialize statistics in CSV format to file. This class ensures the file
  # doesn't remain open beyond when it needs to in order to read or write data.
  class StatisticsCSVFile < Statistics

    # @return [String]
    attr_reader :path

    # @param [String] path
    def initialize(path)
      @path = path
    end

    # @return [Array<Statistics::Record>]
    def read
      File.open(path, "r:UTF-8") do |file|
        statistics = StatisticsCSV.new(io: file)
        statistics.read
      end
    end

    # @param [Statistics::Record] record
    def record(record)
      File.open(path, "a:UTF-8") do |file|
        statistics = StatisticsCSV.new(io: file)
        statistics.record(record)
      end
    end

  end # class
end # module
