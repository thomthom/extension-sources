require 'sketchup.rb'

require 'json'

require 'tt_extension_sources/debug'
require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/extension_sources_controller'
require 'tt_extension_sources/extension_sources_dialog'
require 'tt_extension_sources/extension_sources_manager'

module TT::Plugins::ExtensionSources

  # * Track startup timings. Keep raw log. Keep separate cache of average.
  # * Reload function.
  # * Reorder source paths.
  # * Import/export function.
  # * Undo/redo function.

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
