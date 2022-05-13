require 'logger'

require 'tt_extension_sources/app/settings'
require 'tt_extension_sources/controller/extension_sources_controller'
require 'tt_extension_sources/system/console'
require 'tt_extension_sources/system/os'

module TT::Plugins::ExtensionSources
  # The application logic for Extension Sources.
  class App

    # This will boot the extension sources manager and load files from the
    # list of additional load-paths.
    def boot
      extension_sources_controller.boot
    end

    # @return [AppSettings]
    def settings
      @settings ||= AppSettings.new(EXTENSION[:product_id])
      @settings
    end

    # @return [Logger]
    def logger
      if @logger.nil?
        console = SketchUpConsole.new(SKETCHUP_CONSOLE)
        @logger = Logger.new(console)
        @logger.level = settings.log_level
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{severity}: #{msg}\n"
        end
      end
      @logger
    end

    # @return [ExtensionSourcesController]
    def extension_sources_controller
      @extension_sources_controller ||= ExtensionSourcesController.new(
        logger: logger
      )
      @extension_sources_controller
    end

    # @return [ExtensionSourcesDialog]
    def open_extension_sources_dialog
      controller = extension_sources_controller
      controller.open_extension_sources_dialog
    end

    # @return [ExtensionSourcesDialog]
    def close_extension_sources_dialog
      controller = extension_sources_controller
      controller.close_extension_sources_dialog
    end

  end # class
end # module
