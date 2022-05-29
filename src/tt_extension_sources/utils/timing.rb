require 'stringio'

module TT::Plugins::ExtensionSources
  # Include to provide utility methods for timing.
  class Timing

    # Immutable measurement data for timing results.
    class Measurement

      # @return [Float]
      attr_reader :start, :end, :lapsed

      # @return [String, nil]
      attr_reader :label

      # @param [Float] start_time
      # @param [Float] end_time
      # @param [String, nil] label
      def initialize(start_time, end_time, label: nil)
        @label = label
        @start = start_time
        @end = end_time
        @lapsed = @end - @start
      end

      # @return [String]
      def to_s
        @str ||= compile_string
        @str
      end

      private

      # @return [String]
      def compile_string
        if @label
          "#{@label}: #{format_time_duration(@lapsed)}"
        else
          format_time_duration(@lapsed)
        end
      end

      # @return [String]
      def format_time_duration(duration)
        sprintf("%.4fs", duration)
      end

    end # class Measurement

    # @param [String, nil] title
    def initialize(title: nil)
      @title = title
      @measurements = []
    end

    # @param [String, nil] label
    def measure(label: nil, &block)
      start = Time.now
      result = block.call
      @measurements << Measurement.new(start, Time.now, label: label)
      result
    end

    # @param [String] prefix Line prefix for each measurement.
    # @return [String]
    def format(prefix: '')
      output = StringIO.new
      output.puts(@title) if @title
      @measurements.each { |measurement|
        output.puts("#{prefix}#{measurement}")
      }
      output.string.rstrip
    end

    # @return [String]
    def to_s
      format
    end

  end # class
end # module
