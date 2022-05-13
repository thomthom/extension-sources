require 'logger'

require 'tt_extension_sources/app/settings'

module TT::Plugins::ExtensionSources
  # The application settings interface for Extension Sources.
  class AppSettings < Settings

    # @param [Symbol] product_id the key for the settings to be stored under.
    def initialize(product_id)
      super(product_id)
    end

    # Settings this will not automatically reflect the app's debug state.
    # It will take effect upon next start.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app_settings.debug = true
    #
    # @return [Boolean]
    define :debug, false

    # Settings this will not automatically reflect the app's log level.
    # It will take effect upon next start.
    #
    # @example
    #   TT::Plugins::ExtensionSources.app_settings.log_level = Logger::DEBUG
    #
    # @return [Integer]
    define :log_level, Logger::WARN

  end # class
end # module
