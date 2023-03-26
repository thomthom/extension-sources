require 'logger'

require 'tt_extension_sources/system/settings'

module TT::Plugins::ExtensionSources
  # The application settings interface for Extension Sources.
  #
  # @example
  #   TT::Plugins::ExtensionSources.app.settings.to_h
  class AppSettings < Settings

    # @param [Symbol] product_id the key for the settings to be stored under.
    def initialize(product_id)
      super(product_id)
    end

    # Uses a hook on `Sketchup.require` to more accurately detect load errors.
    # This will reduce quality of recorded data as timings as result of load
    # errors will not be recorded.
    #
    # @note This setting takes effect upon next start of SketchUp.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app.settings.use_require_hook = false
    #
    # @return [Boolean]
    define :use_require_hook, true

    # @note This setting takes effect upon next start of SketchUp.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app.settings.log_level = Logger::DEBUG
    #
    # @return [Integer]
    define :log_level, Logger::WARN

    # @note This setting takes effect upon next start of SketchUp.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app.settings.debug = true
    #
    # @return [Boolean]
    define :debug, false

    # @api private
    #
    # @example
    #   app = TT::Plugins::ExtensionSources.app
    #   app.settings.debug_version_check = true
    #
    # @return [Boolean]
    define :debug_version_check, false

    # @api private
    #
    # @example
    #   app = TT::Plugins::ExtensionSources.app
    #   app.settings.debug_use_cached_scan_results = true
    #
    # @return [Boolean]
    define :debug_use_cached_scan_results, false

    # @api private
    #
    # @example
    #   app = TT::Plugins::ExtensionSources.app
    #   app.settings.debug_dump_cached_scan_results = true
    #
    # @return [Boolean]
    define :debug_dump_cached_scan_results, false

  end # class
end # module
