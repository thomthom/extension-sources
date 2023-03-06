require 'tt_extension_sources/model/system_interface'
require 'tt_extension_sources/model/version'

require 'pathname'
require 'stringio'
require 'tmpdir'

module TT::Plugins::ExtensionSources

  class TestSystem < SystemInterface

    def initialize
      @os = TestOS.new
      @ui = TestUI.new
      @metadata = {
        extension_sources_version: Version.new(1, 2, 3),
        sketchup_version: Version.new(22, 1, 0),
        ruby_version: Version.new(2, 7, 2),
      }
    end

    def metadata
      @metadata
    end

    def require(path)
      raise NotImplementedError
    end

    def os
      @os
    end

    def ui
      @ui
    end

  end # class

  class TestUI < UIInterface

    # TODO: Match constants with SketchUp.
    module Constants
      MB_OK = 0
      MB_OKCANCEL = 1
      MB_ABORTRETRYIGNORE = 2
      MB_YESNOCANCEL = 3
      MB_YESNO = 4
      MB_RETRYCANCEL = 5
      MB_MULTILINE = 6

      IDOK = 0
      IDCANCEL = 1
      IDABORT = 2
      IDRETRY = 3
      IDIGNORE = 4
      IDYES = 5
      IDNO = 6
    end

    def initialize
      @console = TestConsole.new
    end

    def select_directory(**options)
      nil
    end

    def select_file(type:, title:, directory: nil, filename: nil, filter: nil)
      nil
    end

    def messagebox(message, type: nil)
      case type
      when Constants::MB_OK
        Constants::IDOK
      when Constants::MB_OKCANCEL
        Constants::IDCANCEL
      when Constants::MB_ABORTRETRYIGNORE
        Constants::IDABORT
      when Constants::MB_YESNOCANCEL
        Constants::IDCANCEL
      when Constants::MB_YESNO
        Constants::IDNO
      when Constants::MB_RETRYCANCEL
        Constants::IDCANCEL
      when Constants::MB_MULTILINE
        Constants::IDOK # TODO: ?
      end
    end

    def console
      @console
    end

  end # class

  class TestOS < OSInterface

    def windows?
      true
    end

    def macos?
      false
    end

    def app_data_path
      Pathname.new(Dir.tmpdir)
    end

  end # class

  class TestConsole < StringIO

    def show
    end

    def hide
    end

  end # class

end # module
