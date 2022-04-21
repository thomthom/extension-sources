module TT::Plugins::ExtensionSources
  module Execution

    # @param [Float] seconds
    # @return [Integer] Timer ID
    def self.delay(seconds, &block)
      done = false
      UI.start_timer(seconds, false) do
        next if done
        done = true
        block.call
      end
    end

    # @return [Integer] Timer ID
    def self.defer(&block)
      self.delay(0.0, &block)
    end


    class Debounce

      # @param [Float] delay in seconds
      def initialize(delay, &block)
        @block = block
        @delay = delay
        @time_out_timer = nil
      end

      # @return [nil]
      def call
        if @time_out_timer
          UI.stop_timer(@time_out_timer)
          @time_out_timer = nil
        end
        @time_out_timer = UI.start_timer(@delay, &@block)
        nil
      end

    end # class

  end
end # module
