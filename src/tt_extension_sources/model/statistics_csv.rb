require 'csv'

require 'tt_extension_sources/model/statistics'

module TT::Plugins::ExtensionSources
  # Serialize statistics in CSV format.
  class StatisticsCSV < Statistics

    # The names of the statistics headers.
    HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze

    # @return [IO]
    attr_reader :io

    # @param [IO] io
    def initialize(io:)
      @io = io
    end

    # @return [Array<Statistics::Record>]
    def read
      @io.rewind
      csv = CSV.new(@io,
        headers: :first_row,
        return_headers: false,
        **default_options
      )
      csv.read.map { |record|
        sketchup, path, load_time, timestamp = record
        Statistics::Record.new(sketchup: sketchup, path: path, load_time: load_time, timestamp: timestamp)
      }
    end

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
