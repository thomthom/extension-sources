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

    # Settings this will not automatically reflect the app's debug state.
    # It will take effect upon next start.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app.settings.debug = true
    #
    # @return [Boolean]
    define :debug, false

    # Settings this will not automatically reflect the app's log level.
    # It will take effect upon next start.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app.settings.log_level = Logger::DEBUG
    #
    # @return [Integer]
    define :log_level, Logger::WARN

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
    #   app.settings.debug_use_cached_scan_results = true
    #
    # @return [Boolean]
    define :debug_dump_cached_scan_results, false

  end # class
end # module
