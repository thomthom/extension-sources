require 'sketchup.rb'

require 'tt_extension_sources/debug'
require 'tt_extension_sources/extension_sources_controller'

module TT::Plugins::ExtensionSources

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

  unless file_loaded?(__FILE__)
    menu_name = Sketchup.version.to_f < 21.1 ? 'Plugins' : 'Developer'
    menu = UI.menu(menu_name)
    menu.add_item('Extension Sources…') {
      self.open_extension_sources_dialog
    }
    file_loaded(__FILE__)
  end

end # module
