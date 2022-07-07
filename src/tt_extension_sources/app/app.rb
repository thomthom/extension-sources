require 'logger'

require 'tt_extension_sources/app/settings'
require 'tt_extension_sources/controller/extension_sources_controller'
require 'tt_extension_sources/model/version'
require 'tt_extension_sources/utils/inspection'
require 'tt_extension_sources/system/console'
require 'tt_extension_sources/system/os'

module TT::Plugins::ExtensionSources
  # The application logic for Extension Sources.
  class App

    include Inspection

    # @return [ErrorHandler, nil]
    attr_reader :error_handler

    def initialize(error_handler: nil)
      logger.debug { "#{self.class.object_name} initialize" }
      @error_handler = error_handler
    end

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
      metadata = {
        extension_version: Version.parse(EXTENSION[:version]).to_a,
        sketchup_version: Version.parse(Sketchup.version).to_a,
        ruby_version: Version.parse(RUBY_VERSION).to_a,
      }
      @extension_sources_controller ||= ExtensionSourcesController.new(
        settings: settings,
        metadata: metadata,
        logger: logger,
        error_handler: error_handler,
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
