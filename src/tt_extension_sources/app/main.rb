require 'sketchup'

require 'tt_extension_sources/app/app'
require 'tt_extension_sources/app/debug'

module TT::Plugins::ExtensionSources

  # @return [App]
  def self.app
    @app ||= App.new
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

  unless file_loaded?(__FILE__)
    cmd = UI::Command.new('Extension Sources…') {
      self.app.open_extension_sources_dialog
    }
    cmd.tooltip = 'Extension Sources'
    cmd.status_bar_text = 'Open the Extension Sources Dialog.'
    cmd.large_icon = self.toolbar_icon('extension_sources-32x32')
    cmd.small_icon = self.toolbar_icon('extension_sources-32x32')
    cmd_open_extension_sources_dialog = cmd

    menu_name = Sketchup.version.to_f < 21.1 ? 'Plugins' : 'Developer'
    menu = UI.menu(menu_name)
    menu.add_item(cmd_open_extension_sources_dialog)

    toolbar = UI::Toolbar.new('Extension Sources')
    toolbar.add_item(cmd_open_extension_sources_dialog)
    toolbar.show if toolbar.get_last_state != TB_HIDDEN

    file_loaded(__FILE__)

    self.app.boot
  end

end # module
