require 'tt_extension_sources/model/extension_loader'
require 'tt_extension_sources/model/statistics'
require 'tt_extension_sources/model/system_interface'
require 'tt_extension_sources/model/version'

require 'pathname'
require 'stringio'
require 'tmpdir'

module TT::Plugins::ExtensionSources

  class TestSystem < SystemInterface

    attr_reader :sketchup

    def initialize(use_require_hook: false)
      @os = TestOS.new
      @ui = TestUI.new
      @sketchup = TestSketchUp.new(system: self)
      @extensions = TestExtensionManager.new
      @metadata = {
        extension_sources_version: Version.new(1, 2, 3),
        sketchup_version: Version.new(22, 1, 0),
        ruby_version: Version.new(2, 7, 2),
      }
      @use_require_hook = use_require_hook

      if @use_require_hook
        ExtensionLoader::RequireHook.install_to(@sketchup)
      end
    end

    def metadata
      @metadata
    end

    def require(path)
      Kernel.require(path)
    rescue Exception => exception
      _e = exception # Allowing VSCode debugger to inspect the error.
      # Simulate Sketchup.require.
      false
    end

    # @param [String] path
    # @param [Timing, nil] timing
    # @return [ExtensionLoader::RequireHook::RequireResult]
    def require_with_errors(path, timing)
      if @use_require_hook
        @sketchup.es_hook_require_with_errors(path, timing)
      else
        ExtensionLoader::RequireHook::RequireResult.new(
          value: @sketchup.require,
          error: false,
        )
      end
    end

    # @return [TestExtensionManager]
    def extensions
      @extensions
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

  class TestStatistics < Statistics

    # @return [Array<Statistics::Record>]
    attr_reader :rows

    def initialize
      @rows = []
    end

    def record(row)
      @rows << row
    end

  end # class

  class TestExtension

    # @return [String]
    attr_accessor :copyright

    # @return [String]
    attr_accessor :creator

    # @return [String]
    attr_accessor :description

    # @return [String]
    attr_accessor :name

    # @return [String]
    attr_accessor :version

    # @return [String]
    attr_reader :id

    # @return [String]
    attr_reader :version_id

    # Path to the root Ruby file that initialized the extension object.
    # @return [String]
    attr_reader :extension_path

    # Path to the Ruby file to be loaded when the extension is enabled.
    # @return [String]
    attr_reader :path

    def initialize(name, path)
      @name = name
      @description = ''
      @path = path
      @id = ''
      @version_id = ''

      # We use the global function here to get the file
      # path of the caller, then parse out just the path from the return
      # value.
      @extension_path = ''
      stack = caller_locations(1, 1)
      if stack && stack.length > 0 && File.exist?(stack[0].path)
        @extension_path = stack[0].path
      end

      @version = '1.0'
      # Default values for extensions copyright and creator should be empty.
      # These two values should be set when registering your extension.
      @creator = ''
      @copyright = ''

      @loaded = false
      @registered = false

      # When an extension is registered with Sketchup.register_extension,
      # SketchUp will then update this setting if the user makes changes
      # in the Preferences > Extensions panel.
      @load_on_start = false
    end

    # Loads the extension, which is the equivalent of checking its checkbox
    # in the Preferences > Extension panel.
    def check
      # # If we're already registered, reregister to initiate the load.
      # if @registered
      #   Sketchup.register_extension(self, true)
      # else
      #   # If we're not registered, just require the implementation file.
      #   success = Sketchup::require(@path)
      #   if success
      #     @loaded = true
      #     return true
      #   else
      #     return false
      #   end
      # end
      load
    end

    # Unloads the extension, which is the equivalent of unchecking its checkbox
    # in the Preferences > Extension panel.
    def uncheck
      # If we're already registered, re-register to initiate the unload.
      if @registered
        # Sketchup.register_extension(self, false)
        unload
      end
    end

    # Get whether this extension has been loaded.
    def loaded?
      return @loaded
    end

    # Get whether this extension is set to load on start of SketchUp.
    def load_on_start?
      return @load_on_start
    end

    # Get whether this extension has been registered with SketchUp via the
    # Sketchup.register_extension method.
    def registered?
      return @registered
    end

    # @private
    # This method is called by SketchUp when the extension is registered via the
    # Sketchup.register_extension method. NOTE: This is an internal method that
    # should not be called from Ruby.
    def register_from_sketchup
      @registered = true
    end

    # @private
    # This is called by SketchUp when the extension is unloaded via the UI.
    # NOTE: This is an internal method that should not be called from Ruby.
    def unload
      @load_on_start = false
    end

    # @private
    # This is called by SketchUp when the extension is loaded via the UI.
    # NOTE: This is an internal method that should not be called from Ruby.
    def load
      # success = Sketchup::require(@path)
      # if success
      #   @load_on_start = true
      #   @loaded = true
      #   return true
      # else
      #   return false
      # end
      @load_on_start = true
      @loaded = true
    end

  end # class

  class TestExtensionManager

    include Enumerable

    # @param [Array<TestExtension>]
    def initialize(extensions: [])
      @extensions = extensions
    end

    # @todo Is it true that the index starts at 1?
    # @note Index starts at 1.
    #
    # @overload [](index)
    #   @param [Integer] index
    #
    # @overload [](extension_name)
    #   @param [String] extension_name
    #
    # @overload [](extension_ew_id)
    #   @param [String] extension_ew_id
    #
    # return [TestExtension]
    def [](index_or_name)
      case index_or_name
      when Integer
        return @extensions[index_or_name]
      when String
        return @extensions.find { |extension| extension.name == index_or_name }
      else
        raise TypeError
      end
    end

    # @return [Integer]
    def size
      @extensions.size
    end
    alias_method :length, :size

    # @yieldparam [TestExtension] extension
    def each(&block)
      @extensions.each(&block)
    end

    # The keys method is used to get a list of keys in the ExtensionsManager,
    # which are the same as the names of the extensions.
    #
    # @return [Array<String>]
    def keys
      @extensions.map(&:name)
    end

    # @param [TestExtension] extension
    def <<(extension)
      @extensions << extension
    end

  end # class

  # TEST_SKETCHUP = TestSketchUp.new(system: @system)
  class TestSketchUp

    # @param [SystemInterface] system
    def initialize(system:)
      @system = system
    end

    # @param [String] path
    # @return [Boolean]
    def require(path)
      @system.require(path)
    end

    # @return [TestExtensionManager]
    def extensions
      @system.extensions
    end

    # @param [TestExtension] extension
    # @param [Boolean] load_on_start
    # @return [Boolean] `true` if extension registered properly.
    def register_extension(extension, load_on_start = false)
      return false if extensions.any? { |ex| ex.name == extension.name }

      extension.register_from_sketchup
      extensions << extension

      if load_on_start
        unless @system.require(extension.path)
          return false
        end

        extension.check
      end

      true
    end

  end # class

end # module
