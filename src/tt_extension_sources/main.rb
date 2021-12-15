require 'sketchup.rb'

require 'json'

require 'tt_extension_sources/debug'

module TT::Plugins::ExtensionSources

  class ExtensionSource

    attr_accessor :path, :enabled

    # @param [String] path
    # @param [Boolean] enabled
    def initialize(path:, enabled: true)
      @data = {
        path: path,
        enabled: enabled,
      }
    end

    # @return [Hash]
    def to_hash
      @data.dup
    end

    # @return [Hash]
    def as_json(options={})
      # https://stackoverflow.com/a/40642530/486990
      to_hash
    end

    # @return [String]
    def to_json(*args)
      @data.to_json(*args)
    end

  end # class

  def self.open_extension_sources_dialog
    puts 'Extension Sources...'
    [
      {
        path: 'C:/Users/Thomas/SourceTree/TrueBend/src',
        enabled: true,
      }
    ]
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
