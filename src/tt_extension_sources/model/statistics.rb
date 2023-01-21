require 'csv'

module TT::Plugins::ExtensionSources
  class Statistics

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
