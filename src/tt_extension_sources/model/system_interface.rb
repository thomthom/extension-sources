require 'pathname'

module TT::Plugins::ExtensionSources
  # Interface for the host application (SketchUp).
  #
  # This is used to allow decoupling between the core logic and the host
  # application, enabling tests to run without SketchUp. It also allows for
  # for testing closer to the UI boundary as that can be then mocked.
  class SystemInterface

    # return [Hash]
    def metadata
      raise NotImplementedError
    end

    # return [Boolean]
    def require(path)
      raise NotImplementedError
    end

    # @param [String] path
    # @param [Timing, nil] timing
    # @return [ExtensionLoader::RequireHook::RequireResult]
    def require_with_errors(path, timing)
      raise NotImplementedError
    end

    # @return [Sketchup::ExtensionsManager]
    def extensions
      raise NotImplementedError
    end

    # return [OSInterface]
    def os
      raise NotImplementedError
    end

    # return [UIInterface]
    def ui
      raise NotImplementedError
    end

  end # class

  # Interface for UI related application logic.
  class UIInterface

    # @param [Hash] options
    #   The dialog can be customized by providing a hash or named arguments of
    #   options.
    #
    # @option options [String] :title (nil) The title for the dialog.
    #
    # @option options [String] :directory (nil) Force the starting directory for
    #   the dialog. If not specified the last chosen directory will be used.
    #
    # @option options [Boolean] :select_multiple (false) Set to true to allow
    #   multiple items to be selected.
    #
    # @return [String, Array<String>, nil] A string with the full path of the
    #   directory selected when `:select_multiple` option is set to `false`
    #   otherwise an array of strings or `nil` if the user cancelled.
    def select_directory(**options)
      raise NotImplementedError
    end

    # @param [:open, :close] type Type of file dialog to display.
    # @param [String] title
    # @param [Pathname, String, nil] directory
    # @param [Hash{String=>Array<String>}, nil] filter
    def select_file(type:, title:, directory: nil, filename: nil, filter: nil)
      raise NotImplementedError
    end

    # @param [String] message
    # @param [Integer] type
    # @return [Integer]
    def messagebox(message, type: nil)
      raise NotImplementedError
    end

    # The type annotation here is to aid IDEs. The requirement is a
    # combination of all type params (`AND` not `OR`).
    #
    # @return [IO, #show, #hide]
    def console
      # Is this part of the App? More than just UI. It's IO.
      raise NotImplementedError
    end

  end # class

  # Interface to return information about the host system/OS.
  class OSInterface

    # @return [Boolean]
    def windows?
      raise NotImplementedError
    end

    # @return [Boolean]
    def macos?
      raise NotImplementedError
    end

    # @return [Pathname]
    def app_data_path
      raise NotImplementedError
    end

  end # class

end # module
