require 'sketchup'

require 'tt_extension_sources/app/app'
require 'tt_extension_sources/app/debug'

module TT::Plugins::ExtensionSources

  # @return [App]
  def self.app
    @app ||= App.new(error_handler: Bootstrap::ERROR_REPORTER)
    @app
  end

  # @private
  # Absolute path to location of image resources.
  IMAGES_PATH = File.join(PATH, 'images').freeze
  private_constant :IMAGES_PATH

  # @private
  # File extension for toolbar images on the current OS.
  TOOLBAR_IMAGE_EXTENSION = OS.mac? ? 'pdf' : 'svg'
  private_constant :TOOLBAR_IMAGE_EXTENSION

  # @param [String] basename Base name for toolbar icon resource.
  # @return [String] Absolute path to toolbar icon resource.
  def self.toolbar_icon(basename)
    filename = "#{basename}.#{TOOLBAR_IMAGE_EXTENSION}"
    File.join(IMAGES_PATH, filename)
  end

  # @param [String] title
  # @return [UI::Command]
  def self.create_command(title, &block)
    UI::Command.new(title) {
      begin
        block.call
      rescue Exception => exception
        ERROR_REPORTER.handle(exception)
      end
    }
  end

  unless file_loaded?(__FILE__)
    cmd = self.create_command('Extension Sources…') {
      self.app.open_extension_sources_dialog
    }
    cmd.tooltip = 'Extension Sources'
    cmd.status_bar_text = 'Open the Extension Sources Dialog.'
    cmd.large_icon = self.toolbar_icon('extension_sources-32x32')
    cmd.small_icon = self.toolbar_icon('extension_sources-32x32')
    cmd_open_extension_sources_dialog = cmd

    cmd = self.create_command('Extension Sources…') {
      self.app.toggle_ruby_console
    }
    cmd.set_validation_proc {
      # TODO: Ideally this proc logic should be in /app.
      SKETCHUP_CONSOLE.visible? ? MF_CHECKED : MF_ENABLED
    }
    cmd.tooltip = 'Ruby Console'
    cmd.status_bar_text = 'Toggle the Ruby Console.'
    cmd.large_icon = self.toolbar_icon('ruby_console-32x32')
    cmd.small_icon = self.toolbar_icon('ruby_console-32x32')
    cmd_toggle_ruby_console = cmd

    menu_name = Sketchup.version.to_f < 21.1 ? 'Plugins' : 'Developer'
    menu = UI.menu(menu_name)
    menu.add_item(cmd_open_extension_sources_dialog)

    toolbar = UI::Toolbar.new('Extension Sources')
    toolbar.add_item(cmd_open_extension_sources_dialog)
    toolbar.show if toolbar.get_last_state != TB_HIDDEN

    toolbar = UI::Toolbar.new('Ruby Console')
    toolbar.add_item(cmd_toggle_ruby_console)
    toolbar.show if toolbar.get_last_state != TB_HIDDEN

    file_loaded(__FILE__)

    self.app.boot
  end

end # module
