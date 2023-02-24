require 'ruby-prof'

module ProfileRunner

  PROJECT_PATH = File.expand_path('..', __dir__)
  SOURCE_PATH = File.join(PROJECT_PATH, 'src')

  $LOAD_PATH << SOURCE_PATH

  def self.start(&block)
    profile = RubyProf::Profile.new
    profile.start
    block.call
    result = profile.stop

    printer = RubyProf::CallStackPrinter.new(result)
    printer.print($stdout)
  end

end

# Define the nested extension namespace.
module TT
  module Plugins
    module ExtensionSources
    end
  end
end
