module TT::Plugins::ExtensionSources
  # Processes the raw data from {Statistics#read} into a nested hierarchy based
  # on path (extension) and SketchUp version.
  #
  # @see #report
  class StatisticsReporter

    # The returned nested hash has the following structure:
    #
    # ```
    # data[path] = {
    #   total: { ... }
    #   versions: {
    #     "22.0.0": { ... },
    #     "23.0.0": { ... },
    #   }
    # }
    # ```
    #
    # ```rb
    # data = reporter.report
    # rows = data[path][:total]
    # ```
    #
    # ```rb
    # data = reporter.report
    # data[path][:versions].each { |sketchup_version, rows|
    #   # ...
    # }
    # ```
    #
    # The rows is an `Array` or `Hash`es with the following structure:
    #
    # ```
    # row = { min:, max:, mean:, median:, count: }
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
        all_times = []

        report[path] = {
          total: nil,
          versions: {},
        }

        sketchup_versions.each { |sketchup, times|
          all_times.concat(times)

          min, max = times.minmax
          report[path][:versions][sketchup] = {
            min: min,
            max: max,
            mean: times.sum.to_f / times.size.to_f,
            median: median(times),
            count: times.size,
          }
        }

        min, max = all_times.minmax
        report[path][:total] = {
          min: min,
          max: max,
          mean: all_times.sum.to_f / all_times.size.to_f,
          median: median(all_times),
          count: all_times.size,
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
