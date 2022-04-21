require 'tt_extension_sources/execution'
require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/extension_sources_dialog'
require 'tt_extension_sources/extension_sources_manager'

module TT::Plugins::ExtensionSources
  class ExtensionSourcesController

    # TODO: Use Logger
    # https://stackoverflow.com/a/36659911/486990
    #
    # def initialize(log_device: nil)
    #   @logger = Logger.new(log_device)
    #
    # def initialize(logger: nil)
    #   @logger = logger || Logger.new(nil)

    def initialize
      @extension_sources_manager = nil # TODO: Init here, boots the rb loading.
      @extension_sources_dialog = nil

      @sync = Execution::Debounce.new(0.0, &method(:sync))
    end

    # This will boot the extension sources manager and load files from the
    # list of additional load-paths.
    def boot
      # This will init the extension sources manager.
      manager = self.extension_sources_manager
      nil
    end

    # @return [ExtensionSourcesDialog]
    def open_extension_sources_dialog
      unless extension_sources_dialog.visible?

        extension_sources_dialog.on(:boot) do |dialog|
          sources = extension_sources_manager.sources
          dialog.update(sources)
        end

        extension_sources_dialog.on(:add_path) do |dialog|
          add_path(dialog)
        end

        extension_sources_dialog.on(:edit_path) do |dialog, path|
          edit_path(dialog, path)
        end

        extension_sources_dialog.on(:remove_path) do |dialog, path|
          remove_path(dialog, path)
        end

        extension_sources_dialog.on(:reload_path) do |dialog, path|
          reload_path(dialog, path)
        end

        extension_sources_dialog.on(:import_paths) do |dialog|
          import_paths(dialog)
        end

        extension_sources_dialog.on(:export_paths) do |dialog|
          export_paths(dialog)
        end

      end

      extension_sources_dialog.show
      extension_sources_dialog
    end

    # @return [Boolean]
    def close_extension_sources_dialog
      # NOTE: Deliberately using the instance variable here as the getter will
      #       initialize the dialog.
      @extension_sources_dialog&.close
    end

    # @param [ExtensionSourcesManager] sources_manager
    # @param [Symbol] event
    # @param [ExtensionSource] source
    def on_sources_changed(sources_manager, event, source)
      puts "STATUS: #{self.class.name.split('::').last} on_sources_changed: #{event} - ##{source&.source_id}: #{source&.path}"
      @sync.call
    end

    private

    # @param [ExtensionSourcesDialog] dialog
    def add_path(dialog)
      path = UI.select_directory(title: "Select Extension Source Directory")
      return if path.nil?

      extension_sources_manager.add(path)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Integer] source_id
    def edit_path(dialog, source_id)
      source = extension_sources_manager.find_by_source_id(source_id)
      raise "found no source path for: #{source_id}" if source.nil?

      title = "Select Extension Source Directory"
      path = loop do
        path = UI.select_directory(title: title, directory: source.path)
        return if path.nil?

        if extension_sources_manager.include_path?(path)
          message = "Source path '#{path}' already exists. Choose a different path?"
          result = UI.messagebox(message, MB_OKCANCEL)
          next if result == IDOK

          return
        end

        break path
      end

      extension_sources_manager.update(source_id: source_id, path: path)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Integer] source_id
    def remove_path(dialog, source_id)
      source = extension_sources_manager.remove(source_id)
      raise "found no source path for: #{source_id}" if source.nil?
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Integer] source_id
    def reload_path(dialog, source_id)
      puts "reload_path(#{source_id})"

      source = extension_sources_manager.find_by_source_id(source_id)
      raise "found no source path for: #{source_id}" if source.nil?

      puts "> Path: #{source.path}"

      pattern = "#{source.path}/**/*.rb"
      num_files = begin
        original_verbose = $VERBOSE
        $VERBOSE = nil
        Dir.glob(pattern).each { |path|
          # puts "  * #{path}"
          load path
        }.size
      rescue Exception
        SKETCHUP_CONSOLE.show
        raise
      ensure
        $VERBOSE = original_verbose
      end
      puts "> Reloaded #{num_files} files"
    end

    # @param [ExtensionSourcesDialog] dialog
    def export_paths(dialog)
      default_file = ExtensionSourcesManager::EXTENSION_SOURCES_JSON
      path = UI.savepanel("Export Source Paths", nil, default_file)
      return if path.nil?

      if File.exist?(path)
        # TODO: Prompt to overwrite.
        warn "Overwriting existing file: #{path}"
      end

      puts "Exporting to: #{path}"
      extension_sources_manager.export(path)
    end

    # @param [ExtensionSourcesDialog] dialog
    def import_paths(dialog)
      default_file = ExtensionSourcesManager::EXTENSION_SOURCES_JSON
      path = UI.openpanel("Import Source Paths", nil, default_file)
      return if path.nil?

      raise "path not found: #{path}" unless File.exist?(path)

      puts "Importing from: #{path}"
      extension_sources_manager.import(path)
    end

    # @return [ExtensionSourcesManager]
    def extension_sources_manager
      @extension_sources_manager ||= ExtensionSourcesManager.new.tap { |manager|
        manager.add_observer(self, :on_sources_changed)
      }
      @extension_sources_manager
    end

    # @return [ExtensionSourcesDialog]
    def extension_sources_dialog
      @extension_sources_dialog ||= ExtensionSourcesDialog.new
      @extension_sources_dialog
    end

    def sync
      puts "STATUS: #{self.class.name.split('::').last} sync"
      extension_sources_manager.save
      sync_dialog(extension_sources_dialog)
      nil
    end

    def sync_dialog(dialog)
      puts "STATUS: #{self.class.name.split('::').last} sync_dialog"
      sources = extension_sources_manager.sources
      dialog.update(sources)
      nil
    end

  end # class
end # module
