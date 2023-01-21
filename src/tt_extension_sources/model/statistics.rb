require 'csv'

module TT::Plugins::ExtensionSources
  # @abstract
  class Statistics

    # Data structure that holds the recorded statistics.
    #
    # @!attribute sketchup
    #   @return [String] SketchUp version (`Sketchup.version`).
    #
    # @!attribute path
    #   @return [String] The extension source path.
    #
    # @!attribute load_time
    #   @return [Float] The lapsed time it took to load the extension.
    #
    # @!attribute timestamp
    #   @return [Time] The time the record was created.
    #
    Record = Struct.new(:sketchup, :path, :load_time, :timestamp,
      keyword_init: true
    )

    # @abstract
    # @return [Array<Statistics::Record>]
    def read
      raise NotImplementedError
    end

    # @abstract
    # @param [Statistics::Record] row
    def record(row)
      raise NotImplementedError
    end

  end # class
end # module
