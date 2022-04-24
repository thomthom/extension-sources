require 'delegate'

module TT::Plugins::ExtensionSources
  # A wrapper on top of `Sketchup::Console` to allow it to work with the
  # `Logger` class that require `#write` and `#close`.
  class SketchUpConsole < SimpleDelegator

    # @param [Sketchup::Console] console
    def initialize(console = SKETCHUP_CONSOLE)
      __setobj__(console)
    end

    # noop
    def close
    end

  end # class
end # module
