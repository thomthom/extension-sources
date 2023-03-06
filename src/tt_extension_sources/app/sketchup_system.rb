require 'tt_extension_sources/model/system_interface'
require 'tt_extension_sources/system/console'
require 'tt_extension_sources/system/os'

module TT::Plugins::ExtensionSources
  # Implementation of the system interface under SketchUp.
  class SketchUpSystem < SystemInterface

    def initialize
      @os = SketchUpOS.new
      @ui = SketchUpUI.new
      @metadata = {
        extension_sources_version: Version.parse(EXTENSION[:version]),
        sketchup_version: Version.parse(Sketchup.version),
        ruby_version: Version.parse(RUBY_VERSION),
      }
    end

    # return [Hash]
    def metadata
      @metadata
    end

    # return [Boolean]
    def require(path)
      Sketchup.require(path)
    end

    # return [OSInterface]
    def os
      @os
    end

    # return [UIInterface]
    def ui
      @ui
    end

  end # class

  # Interface for UI related application logic.
  class SketchUpUI < UIInterface

    def initialize
      @console = SketchUpConsole.new(SKETCHUP_CONSOLE)
    end

    # @param [Hash] options
    # @return [String, Array<String>, nil]
    def select_directory(**options)
      UI.select_directory(**options)
    end

    # @param [:open, :close] type Type of file dialog to display.
    # @param [String] title
    # @param [Pathname, String, nil] directory
    # @param [Hash{String=>Array<String>}, nil] filter
    def select_file(type:, title:, directory: nil, filename: nil, filter: nil)
      method_name = case type
      when :open; :openpanel
      when :close; :closepanel
      else raise ArgumentError, "invalid type: #{type}"
      end
      args = [title, directory]
      if filter && !filter.empty?
        # Image Files|*.jpg;*.png;||
        # UIname|wildcard||
        # UIname1|wildcard1|UIname2|wildcard2||
        # UIname|wildcard1;wildcard2||
        arg = filter.map { |name, extensions|
          "#{name}|#{extensions.join(';')}"
        }.join('|')
        args << "#{args}||"
      elsif filename
        args << filename
      end
      UI.public_send(method_name, *args)
    end

    # @param [String] message
    # @param [Integer] type
    # @return [Integer]
    def messagebox(message, type: nil)
      args = [message]
      args << type if type
      UI.messagebox(*args)
    end

    # The type annotation here is to aid IDEs. The requirement is a
    # combination of all type params (`AND` not `OR`).
    #
    # @return [IO, #show, #hide, Sketchup::Console, SketchUpConsole]
    def console
      @console
    end

  end # class

  # Interface to return information about the host system/OS.
  class SketchUpOS < OSInterface

    # @return [Boolean]
    def windows?
      OS.windows?
    end

    # @return [Boolean]
    def macos?
      OS.mac?
    end

    # @return [Pathname]
    def app_data_path
      OS.app_data_path
    end

  end # class

end # module
