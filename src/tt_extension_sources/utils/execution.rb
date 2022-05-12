module TT::Plugins::ExtensionSources
  # Utilities for deferring code execution.
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

    # Debounces the block given to the {Debounce} instance.
    #
    # @example
    #   class Counter
    #
    #     def initialize
    #       @value = 0
    #       @update = Execution::Debounce.new(0.0) do
    #         update
    #       end
    #     end
    #
    #     def increment
    #       @value += 1
    #       puts 'Increment...'
    #       @update.call
    #     end
    #
    #     private
    #
    #     def update
    #       puts 'Update!'
    #     end
    #
    #   end
    #
    #   counter = Counter.new
    #   3.times do
    #     counter.increment
    #   end
    #
    #   # Output:
    #   #   Increment...
    #   #   Increment...
    #   #   Increment...
    #   #   Update!
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
