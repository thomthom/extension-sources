require 'sketchup.rb'

require 'json'

require 'tt_extension_sources/debug'
require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/extension_sources_dialog'

module TT::Plugins::ExtensionSources

  # Track startup timings. Keep raw log. Keep separate cache of average.

  def self.open_extension_sources_dialog
    # puts 'Extension Sources...'
    # [
    #   {
    #     path: 'C:/Users/Thomas/SourceTree/TrueBend/src',
    #     enabled: true,
    #   }
    # ]
    @dialog ||= ExtensionSourcesDialog.new
    @dialog.show
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
