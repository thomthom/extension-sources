require 'sketchup.rb'

require 'json'

require 'tt_extension_sources/debug'
require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/extension_sources_dialog'

module TT::Plugins::ExtensionSources

  # * Track startup timings. Keep raw log. Keep separate cache of average.
  # * Reload function.

  def self.extension_sources_manager
    @extension_sources_manager ||= ExtensionSourcesManager.new
    @extension_sources_manager
  end

  def self.open_extension_sources_dialog
    # puts 'Extension Sources...'
    # [
    #   {
    #     path: 'C:/Users/Thomas/SourceTree/TrueBend/src',
    #     enabled: true,
    #   }
    # ]
    @extension_sources_dialog ||= ExtensionSourcesDialog.new
    @extension_sources_dialog.on(:boot) do |dialog|
      sources = self.extension_sources_manager.sources
      dialog.update(sources)
    end
    @extension_sources_dialog.show
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
