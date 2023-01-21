require 'csv'
require 'time'

require 'tt_extension_sources/model/statistics'

module TT::Plugins::ExtensionSources
  # Serialize statistics in CSV format.
  class StatisticsCSV < Statistics

    # @private
    # The names of the statistics headers.
    HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze
    private_constant :HEADERS

    # @return [IO]
    attr_reader :io

    # @param [IO] io
    def initialize(io:)
      @io = io
    end

    # @example
    #   data = File.open(file_path, "r:UTF-8") do |file|
    #     statistics = StatisticsCSV.new(io: file)
    #     statistics.read
    #   end
    #
    # @return [Array<Statistics::Record>]
    def read
      @io.rewind
      csv = CSV.new(@io,
        headers: :first_row,
        return_headers: false,
        **default_options
      )
      csv.read.map { |record|
        sketchup, path, load_time, timestamp = record.fields
        Statistics::Record.new(
          sketchup: sketchup,
          path: path,
          load_time: load_time.to_f,
          timestamp: Time.iso8601(timestamp)
        )
      }
    end

    # @example
    #   row = ...
    #   File.open(file_path, "a:UTF-8") do |file|
    #     statistics = StatisticsCSV.new(io: file)
    #     statistics.record(row)
    #   end
    #
    # @param [Statistics::Record] record
    def record(record)
      csv = CSV.new(@io,
        headers: HEADERS,
        write_headers: @io.size == 0,
        **default_options
      )
      @io.seek(0, IO::SEEK_END)
      csv << [
        record.sketchup,
        record.path,
        record.load_time,
        record.timestamp.iso8601
      ]
    end

    private

    # @return [Hash]
    def default_options
      {
        encoding: 'utf-8',
      }
    end

  end # class
end # module
