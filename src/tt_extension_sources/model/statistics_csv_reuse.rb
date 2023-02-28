require 'csv'
require 'time'

require 'tt_extension_sources/model/statistics'

module TT::Plugins::ExtensionSources
  # Serialize statistics in CSV format.
  class StatisticsCSVReuse < Statistics

    # @private
    # The names of the statistics headers.
    HEADERS = ['SketchUp', 'Path', 'Load Time', 'Timestamp'].freeze
    private_constant :HEADERS

    # @return [IO]
    attr_reader :io

    # @param [IO] io
    def initialize(io:)
      @io = io
      # Writing is written in chunks. Cache the CSV instance to avoid
      # the overhead of creating the object every time.
      @write_csv = CSV.new(@io,
        headers: HEADERS,
        write_headers: @io.size == 0,
        **default_options
      )
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
      # Reading uses different options and reads in bulk. No need to
      # cache the CSV instance.
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
      # Seek to the end to ensure content isn't trunkated in case
      # multiple instances of SketchUp is running.
      @io.seek(0, IO::SEEK_END)
      @write_csv << [
        record.sketchup,
        record.path,
        record.load_time,
        iso8601(record.timestamp)
      ]
      # Flushing to ensure that the file can be written to by
      # multiple instances of SketchUp running the extension.
      @io.flush
    end

    private

    # @private
    # ISO8601 format string when the time is UTC.
    ISO8601_FORMAT_UTC = "%FT%T".freeze
    private_constant :ISO8601_FORMAT_UTC

    # @private
    # ISO8601 format string when the time is not UTC.
    ISO8601_FORMAT = "%FT%T%:z".freeze
    private_constant :ISO8601_FORMAT

    # Optimized version of the standard library's Time#iso8601.
    # It eliminates the fraction argument and calls strftime only
    # once. Reusing the format string to avoid new string allocations.
    #
    # @param [Time] time
    # @return [String]
    def iso8601(time)
      if time.utc?
        time.strftime(ISO8601_FORMAT_UTC)
      else
        time.strftime(ISO8601_FORMAT)
      end
    end

    # @return [Hash]
    def default_options
      {
        encoding: 'utf-8',
      }
    end

  end # class
end # module
