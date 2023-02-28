module TT::Plugins::ExtensionSources
  # Processes the raw data from {Statistics#read} into a nested hierarchy based
  # on path (extension) and SketchUp version.
  #
  # @see #report
  class StatisticsReporter

    # The returned nested hash has the following structure:
    #
    # ```
    # path/sketchup/rows
    # ```
    #
    # ```rb
    # data = reporter.report
    # rows = data[path][sketchup]
    # ```
    #
    # The rows is an `Array` or `Hash`es with the following structure:
    #
    # ```
    # row = { min:, max:, mean:, median: }
    # ```
    #
    # @param [Array<Statistics::Record>] records
    # @return [Hash]
    def report(records)
      report = {}

      grouped = {}
      records.each { |record|
        sketchup, path, load_time, _timestamp = record.values

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

    private

    # @param [Array] items
    def median(items)
      # https://stackoverflow.com/a/20677729/486990
      sorted = items.sort
      mid = (sorted.length - 1) / 2.0
      (sorted[mid.floor] + sorted[mid.ceil]) / 2.0
    end

  end # class
end # module
