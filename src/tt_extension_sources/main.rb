require 'sketchup.rb'

require 'tt_extension_sources/debug'
require 'tt_extension_sources/extension_sources_controller'
require 'tt_extension_sources/os'

module TT::Plugins::ExtensionSources

  IMAGES_PATH = File.join(PATH, 'images').freeze
  TOOLBAR_IMAGE_EXTENSION = OS.windows? ? 'svg' : 'pdf'

  # * Import/export function.
  # * Scan for source paths (find .rb files with Sketchup.register_extension)
  # * Reorder source paths.
  # * Undo/redo function.
  # * Options
  #   * Open Ruby Console at Startup
  # * Select/multi select.
  # * Track startup timings. Keep raw log. Keep separate cache of average.

  # @return [ExtensionSourcesController]
  def self.extension_sources_controller
    @extension_sources_controller ||= ExtensionSourcesController.new
    @extension_sources_controller
  end

  # @return [ExtensionSourcesDialog]
  def self.open_extension_sources_dialog
    app = self.extension_sources_controller
    app.open_extension_sources_dialog
  end

  def self.toolbar_icon(basename)
    filename = "#{basename}.#{TOOLBAR_IMAGE_EXTENSION}"
    File.join(IMAGES_PATH, filename)
  end

  unless file_loaded?(__FILE__)
    cmd = UI::Command.new('Extension Sources…') {
      self.open_extension_sources_dialog
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

    self.extension_sources_controller.boot
  end

end # module
