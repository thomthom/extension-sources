require 'csv'

module TT::Plugins::ExtensionSources
  class Statistics

    attr_reader :path
    attr_reader :data

    # @param [String] path
    def initialize(path:)
      @path = path
      @data = read(path)
    end

    def report
      report = {}

      grouped = {}
      data.each { |row|
        sketchup, path, load_time, _timestamp = row.fields

        grouped[path] ||= {}
        grouped[path][sketchup] ||= []

        grouped[path][sketchup] << load_time.to_f
      }

      grouped.each { |path, sketchup_versions|
        sketchup_versions.each { |sketchup, times|
          min, max = times.minmax
          mean = times.sum.to_f / times.size.to_f
          median = median(times)

          report[path] ||= {}
          report[path][sketchup] = { min: min, max: max, mean: mean, median: median }
        }
      }

      report
    end

    # @return [String]
    # def inspect(*args)
    #   hex_id = "0x%x" % (object_id << 1)
    #   %{#<ExtensionSource:#{hex_id} id=#{source_id.inspect} path=#{path.inspect} enabled=#{enabled?.inspect}>}
    # end

    private

    # @param [Array] items
    def median(items)
      # https://stackoverflow.com/a/20677729/486990
      sorted = items.sort
      mid = (sorted.length - 1) / 2.0
      (sorted[mid.floor] + sorted[mid.ceil]) / 2.0
    end

    # @param [String] path
    def read(path)
      options = {
        encoding: 'utf-8',
        headers: :first_row,
        return_headers: false,
        # strip: true,
      }
      rows = CSV.read(path, **options)
      rows
    end

  end # class
end # module
