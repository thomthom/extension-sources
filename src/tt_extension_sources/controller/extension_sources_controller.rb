require 'logger'

require 'tt_extension_sources/app/os'
require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/model/extension_sources_manager'
require 'tt_extension_sources/utils/inspection'
require 'tt_extension_sources/utils/execution'
require 'tt_extension_sources/view/extension_sources_dialog'

module TT::Plugins::ExtensionSources
  # Application logic binding the extension sources manager with the UI.
  class ExtensionSourcesController

    # Filename, excluding path, of the JSON file to serialize to/from.
    EXTENSION_SOURCES_JSON = 'extension_sources.json'.freeze

    include Inspection

    # @param [Logger] logger
    def initialize(logger: Logger.new(nil))
      @logger = logger
      @logger.debug { "#{self.class.object_name} initialize" }
      @extension_sources_manager = nil
      @extension_sources_dialog = nil

      @sync = Execution::Debounce.new(0.0, &method(:sync))
    end

    # This will boot the extension sources manager and load files from the
    # list of additional load-paths.
    def boot
      @logger.debug { "#{self.class.object_name} boot" }
      @extension_sources_manager ||= create_extension_sources_manager
      nil
    end

    # @return [ExtensionSourcesDialog]
    def open_extension_sources_dialog
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
      @logger.debug { "#{self.class.object_name} on_sources_changed: #{event} - ##{source&.source_id}: #{source&.path}" }
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
      @logger.info { "#{self.class.object_name} reload_path(#{source_id})" }

      source = extension_sources_manager.find_by_source_id(source_id)
      raise "found no source path for: #{source_id}" if source.nil?

      @logger.info { "#{self.class.object_name} > Path: #{source.path}" }

      pattern = "#{source.path}/**/*.rb"
      num_files = begin
        original_verbose = $VERBOSE
        $VERBOSE = nil
        Dir.glob(pattern).each { |path|
          # @logger.debug { "#{self.class.object_name} * #{path}" }
          load path
        }.size
      rescue Exception
        SKETCHUP_CONSOLE.show
        raise
      ensure
        $VERBOSE = original_verbose
      end
      @logger.info { "#{self.class.object_name} > Reloaded #{num_files} files" }
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

      @logger.info { "#{self.class.object_name} Exporting to: #{path}" }
      extension_sources_manager.export(path)
    end

    # @param [ExtensionSourcesDialog] dialog
    def import_paths(dialog)
      default_file = ExtensionSourcesManager::EXTENSION_SOURCES_JSON
      path = UI.openpanel("Import Source Paths", nil, default_file)
      return if path.nil?

      raise "path not found: #{path}" unless File.exist?(path)

      @logger.info { "#{self.class.object_name} Importing from: #{path}" }
      extension_sources_manager.import(path)
    end

    # @return [ExtensionSourcesManager]
    def extension_sources_manager
      raise '`boot` has not been called yet' if @extension_sources_manager.nil?
      @extension_sources_manager
    end

    # @return [ExtensionSourcesManager]
    def create_extension_sources_manager
      ExtensionSourcesManager.new(logger: @logger, storage_path: sources_json_path).tap { |manager|
        manager.add_observer(self, :on_sources_changed)
      }
    end

    # @return [ExtensionSourcesDialog]
    def extension_sources_dialog
      @extension_sources_dialog ||= create_extension_sources_dialog
      @extension_sources_dialog
    end

    # @return [ExtensionSourcesDialog]
    def create_extension_sources_dialog
      dialog = ExtensionSourcesDialog.new

      dialog.on(:boot) do |dialog|
        sources = extension_sources_manager.sources
        dialog.update(sources)
      end

      dialog.on(:add_path) do |dialog|
        add_path(dialog)
      end

      dialog.on(:edit_path) do |dialog, path|
        edit_path(dialog, path)
      end

      dialog.on(:remove_path) do |dialog, path|
        remove_path(dialog, path)
      end

      dialog.on(:reload_path) do |dialog, path|
        reload_path(dialog, path)
      end

      dialog.on(:import_paths) do |dialog|
        import_paths(dialog)
      end

      dialog.on(:export_paths) do |dialog|
        export_paths(dialog)
      end

      dialog
    end

    # Call whenever extension sources has changed. This will update the UI and
    # serialize the changes to file.
    #
    # @note This should be called via an {Execution::Debounce} to avoid
    #   unnecessary update.
    #
    # @return [nil]
    def sync
      @logger.debug { "#{self.class.object_name} sync" }
      extension_sources_manager.save
      sync_dialog(extension_sources_dialog)
      nil
    end

    # Call whenever the Extension Sources dialog needs to update.
    #
    # @return [nil]
    def sync_dialog(dialog)
      @logger.debug { "#{self.class.object_name} sync_dialog" }
      sources = extension_sources_manager.sources
      dialog.update(sources)
      nil
    end

    # @return [String]
    def storage_dir
      File.join(OS.app_data_path, 'CookieWare', 'Extension Source Manager')
    end

    # The absolute path where the manager will serialize to/from.
    #
    # @return [String]
    def sources_json_path
      File.join(storage_dir, EXTENSION_SOURCES_JSON)
    end

  end # class
end # module
