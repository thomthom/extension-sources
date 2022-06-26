module TT::Plugins::ExtensionSources
  # Bootstrap logic verifying compatibility and settings up error logging before
  # loading the rest of the extension.
  module Bootstrap

    ### CONFIGURATION ### --------------------------------------------------------

    # Indicate this is a debug session.
    extension_debug = Sketchup.read_default(EXTENSION[:product_id], "debug", false)

    # Allow the error reporter to be disabled while developing.
    version_check = Sketchup.read_default(EXTENSION[:product_id], "debug_version_check", true)

    # Minimum version of SketchUp required to run the extension.
    minimum_sketchup_version = 17

    # URI to the extension product page.
    extension_url = "https://github.com/thomthom/extension-sources".freeze


    ### COMPATIBILITY CHECK ### --------------------------------------------------

    if version_check && Sketchup.version.to_i < minimum_sketchup_version

      # Not localized because we don't want the Translator and related
      # dependencies to be forced to be compatible with older SketchUp versions.
      version_name = "20#{minimum_sketchup_version}"
      message = "#{EXTENSION[:name]} require SketchUp #{version_name} or newer."
      messagebox_open = false # Needed to avoid opening multiple message boxes.
      # Defer with a timer in order to let SketchUp fully load before displaying
      # modal dialog boxes.
      UI.start_timer(0, false) {
        unless messagebox_open
          messagebox_open = true
          UI.messagebox(message)
          # Must defer the disabling of the extension as well otherwise the
          # setting won't be saved. I assume SketchUp save this setting after it
          # loads the extension.
          @extension.uncheck
        end
      }

    else # Sketchup.version

      ### ERROR HANDLER ### ------------------------------------------------------

      require "tt_extension_sources/vendor/error-reporter/error_reporter"

      # Sketchup.write_default("TT_ExtensionSources", "ErrorServer", "sketchup.thomthom.local")
      # Sketchup.write_default("TT_ExtensionSources", "ErrorServer", "sketchup.thomthom.net")
      # Sketchup.write_default("TT_ExtensionSources", "ErrorServer", "stg-sketchup.thomthom.net")
      server = Sketchup.read_default(EXTENSION[:product_id], "ErrorServer",
        "sketchup.thomthom.net")

      extension = Sketchup.extensions[EXTENSION[:name]]

      config = {
        :extension_id => EXTENSION[:product_id],
        :extension    => extension,
        :server       => "https://#{server}/api/v1/extension/report_error",
        :support_url  => "#{extension_url}/support",
        :debug        => extension_debug
      }
      # Instance of the error reporter to be used for this extension.
      ERROR_REPORTER = ErrorReporter.new(config)

      begin
        require 'tt_extension_sources/app/main'
      rescue Exception => error
        ERROR_REPORTER.handle(error)
      end

    end # if Sketchup.version

  end # module
end # module
