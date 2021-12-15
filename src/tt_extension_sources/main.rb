require 'sketchup.rb'

module TT::Plugins::ExtensionSources

  def self.open_extension_sources_dialog
    puts 'Extension Sources...'
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
