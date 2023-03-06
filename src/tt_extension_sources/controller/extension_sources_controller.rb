require 'logger'

require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/model/extension_sources_manager'
require 'tt_extension_sources/model/extension_sources_scanner'
require 'tt_extension_sources/model/statistics_csv'
require 'tt_extension_sources/utils/inspection'
require 'tt_extension_sources/utils/execution'
require 'tt_extension_sources/utils/timing'
require 'tt_extension_sources/view/extension_sources_dialog'
require 'tt_extension_sources/view/extension_sources_scanner_dialog'
require 'tt_extension_sources/view/extension_statistics_dialog'

module TT::Plugins::ExtensionSources
  # Application logic binding the extension sources manager with the UI.
  class ExtensionSourcesController

    # @private
    # Filename, excluding path, of the JSON file to serialize to/from.
    EXTENSION_SOURCES_JSON = 'extension_sources.json'.freeze
    private_constant :EXTENSION_SOURCES_JSON

    # @private
    # Filename, excluding path, of the file where the timing logs will be stored.
    EXTENSIONS_TIMING_LOG = 'extension-sources-timings.csv'.freeze
    private_constant :EXTENSIONS_TIMING_LOG

    include Inspection

    # @return [ErrorHandler, nil]
    attr_reader :error_handler

    # @param [SystemInterface] system
    # @param [AppSettings] settings
    # @param [Logger] logger
    # @param [ErrorHandler, nil] error_handler
    def initialize(system:, settings:, logger: Logger.new(nil), error_handler: nil)
      @error_handler = error_handler
      @logger = logger
      @logger.debug { "#{self.class.object_name} initialize" }
      @system = system
      @settings = settings
      # Deferring initialization of the manager because it will cause the
      # extensions to load. Instead the `boot` method takes care of this.
      @extension_sources_manager = nil
      # Dialogs are also lazy-constructed as there is no need to allocate their
      # resources until they are used.
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
      @extension_sources_dialog = nil # Workaround for macOS issue. (#37)
      extension_sources_dialog.show
      extension_sources_dialog
    end

    # @return [Boolean]
    def close_extension_sources_dialog
      # NOTE: Deliberately using the instance variable here as the getter will
      #       initialize the dialog.
      # @extension_sources_dialog&.close # &. Doesn't work in Ruby 2.2
      @extension_sources_dialog.close if @extension_sources_dialog
    end

    # @param [ExtensionSourcesManager] sources_manager
    # @param [Symbol] event
    # @param [ExtensionSource, nil] source
    def on_sources_changed(sources_manager, event, source = nil)
      # @logger.debug { "#{self.class.object_name} on_sources_changed: #{event} - ##{source&.source_id}: #{source&.path}" }
      @logger.debug { "#{self.class.object_name} on_sources_changed: #{event} - ##{source ? source.source_id : nil}: #{source ? source.path : nil}" }
      @sync.call
    end

    private

    # @param [ExtensionSourcesDialog] dialog
    def add_path(dialog)
      path = @system.ui.select_directory(title: "Select Extension Source Directory")
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
        path = @system.ui.select_directory(title: title, directory: source.path)
        return if path.nil?
        return if path == source.path

        if extension_sources_manager.include_path?(path)
          message = "Source path '#{path}' already exists. Choose a different path?"
          result = @system.ui.messagebox(message, type: MB_YESNO)
          next if result == IDYES

          return
        end

        break path
      end

      extension_sources_manager.update(source_id: source_id, path: path)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Integer] source_id
    def remove_path(dialog, source_id)
      source = extension_sources_manager.find_by_source_id(source_id)
      raise "found no source path for: #{source_id}" if source.nil?

      # After undo/redo is implemented this messagebox can be removed.
      message = "Remove path from list of extension sources?\n\nPath: #{source.path}"
      result = @system.ui.messagebox(message, type: MB_YESNO)
      return if result == IDNO

      source = extension_sources_manager.remove(source_id)
      raise "found no source path for: #{source_id}" if source.nil?
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Integer] source_id
    # @param [Hash{String => Object}] changes
    def source_changed(dialog, source_id, changes)
      extension_sources_manager.update(source_id: source_id, **changes)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Array<Hash{Symbol => Hash{Symbol => Object}}>] changes
    def sources_changed(dialog, changes)
      changes.each { |change|
        source_id = change[:source_id]
        properties = change[:properties]
        source_changed(dialog, source_id, properties)
      }
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
          begin
            load path
          rescue Exception => error
            puts error.message
            error_handler.ignore(error) if error_handler
          end
        }.size
      rescue Exception => error
        @system.ui.console.show
        raise
      ensure
        $VERBOSE = original_verbose
      end
      @logger.info { "#{self.class.object_name} > Reloaded #{num_files} files" }
    end

    # @param [ExtensionSourcesDialog] dialog
    def export_paths(dialog)
      path = @system.ui.select_file(type: :save, title: "Export Source Paths",
        filename: EXTENSION_SOURCES_JSON)
      return if path.nil?

      if File.exist?(path)
        # SketchUp 2017+ the dialog itself takes care of prompting to overwrite
        # existing files. No need for the extension to also perform this prompt.
        @logger.info { "#{self.class.object_name} Overwriting existing file: #{path}" }
      end

      @logger.info { "#{self.class.object_name} Exporting to: #{path}" }
      extension_sources_manager.export(path)
    end

    # @param [ExtensionSourcesDialog] dialog
    def import_paths(dialog)
      path = @system.ui.select_file(type: :open, title: "Import Source Paths",
        filename: EXTENSION_SOURCES_JSON)
      return if path.nil?

      raise "path not found: #{path}" unless File.exist?(path)

      @logger.info { "#{self.class.object_name} Importing from: #{path}" }
      extension_sources_manager.import(path)
    rescue ExtensionSourcesManager::ImportError => error
      handle_import_error(error)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [Array<Integer>] selected_ids
    # @param [Integer] target_id
    def reorder(dialog, selected_ids, target_id, before)
      @logger.debug { "#{self.class.object_name} Move Selected Paths: #{selected_ids.inspect} to #{target_id.inspect} (Before: #{before.inspect})" }
      manager = extension_sources_manager
      selected = selected_ids.map { |id| manager.find_by_source_id(id) }
      target = manager.find_by_source_id(target_id)
      position = before ? :before : :after
      params = {
        :sources => selected,
        position => target,
      }
      manager.move(**params)
    end

    # @param [ExtensionSourcesDialog] dialog
    def scan_paths(dialog)
      directory = @system.ui.select_directory(title: "Select Directory to Scan")
      return if directory.nil?

      existing_paths = extension_sources_manager.sources.map(&:path)

      # The scanner might take time. In order to speed up development on
      # processing the scanner results, UI etc, these debug methods can be used
      # to read/write the scanner results to/from a cache.
      if @settings.debug_use_cached_scan_results?
        @logger.debug { "#{self.class.object_name} Using cached scan results: #{debug_scan_dump_path}" }
        results = debug_read_scan_dump(debug_scan_dump_path)
      else

        @logger.info { "#{self.class.object_name} Scanning: #{directory}" }
        scanner = ExtensionSourcesScanner.new
        timing = Timing.new
        paths = timing.measure do
          scanner.scan(directory, exclude: existing_paths)
        end
        @logger.info { "#{self.class.object_name} Scan for extension sources took: #{timing}" }
        @logger.info { "#{self.class.object_name} Found #{paths.size} paths." }
        @logger.debug { "Paths:\n* #{paths.join("\n* ")}" } unless paths.empty?

        results = paths.map { |path|
          ExtensionSource.new(path: path, enabled: true)
        }

        if @settings.debug_dump_cached_scan_results?
          @logger.debug { "#{self.class.object_name} Writing scan results cache to: #{debug_scan_dump_path}" }
          debug_write_scan_dump(debug_scan_dump_path, results)
        end
      end

      @extension_sources_scanner_dialog = nil # Workaround for macOS issue. (#37)
      extension_sources_scanner_dialog.show(results)
    end

    # @return [void]
    def open_statistics
      extension_statistics_dialog.show([])
    end

    # @return [ExtensionSourcesManager]
    def extension_sources_manager
      raise '`boot` has not been called yet' if @extension_sources_manager.nil?
      @extension_sources_manager
    end

    # @return [ExtensionSourcesManager]
    def create_extension_sources_manager
      statistics_file = File.open(timing_log_path, 'a:UTF-8')
      statistics = StatisticsCSV.new(io: statistics_file)

      ExtensionSourcesManager.new(
        system: @system,
        logger: @logger,
        storage_path: sources_json_path,
        statistics: statistics,
      ).tap { |manager|
        manager.add_observer(self, :on_sources_changed)
      }
    rescue ExtensionSourcesManager::ImportError => error
      handle_import_error(error)
    end

    # @return [ExtensionSourcesDialog]
    def extension_sources_dialog
      @extension_sources_dialog ||= create_extension_sources_dialog
      @extension_sources_dialog
    end

    # @return [ExtensionSourcesDialog]
    def create_extension_sources_dialog
      dialog = ExtensionSourcesDialog.new
      dialog.error_handler = error_handler

      dialog.on(:boot) do |dialog|
        sources = extension_sources_manager.sources
        dialog.update(sources)
      end

      dialog.on(:add_path) do |dialog|
        add_path(dialog)
      end

      dialog.on(:edit_path) do |dialog, source_id|
        edit_path(dialog, source_id)
      end

      dialog.on(:remove_path) do |dialog, source_id|
        remove_path(dialog, source_id)
      end

      dialog.on(:reload_path) do |dialog, source_id|
        reload_path(dialog, source_id)
      end

      dialog.on(:source_changed) do |dialog, source_id, changes|
        source_changed(dialog, source_id, changes)
      end

      dialog.on(:sources_changed) do |dialog, changes|
        sources_changed(dialog, changes)
      end

      dialog.on(:import_paths) do |dialog|
        import_paths(dialog)
      end

      dialog.on(:export_paths) do |dialog|
        export_paths(dialog)
      end

      dialog.on(:scan_paths) do |dialog|
        scan_paths(dialog)
      end

      dialog.on(:open_statistics) do |dialog|
        open_statistics
      end

      dialog.on(:reorder) do |dialog, selected_ids, target_id, before|
        reorder(dialog, selected_ids, target_id, before)
      end

      dialog
    end

    # @return [ExtensionSourcesScannerDialog]
    def extension_sources_scanner_dialog
      @extension_sources_scanner_dialog ||= create_extension_sources_scanner_dialog
      @extension_sources_scanner_dialog
    end

    # @return [ExtensionSourcesScannerDialog]
    def create_extension_sources_scanner_dialog
      dialog = ExtensionSourcesScannerDialog.new
      dialog.error_handler = error_handler

      dialog.on(:boot) do |dialog|
        dialog.update(dialog.report)
      end

      dialog.on(:accept) do |dialog, selected|
        dialog.close
        add_extension_sources(selected)
      end

      dialog.on(:cancel) do |dialog|
        dialog.close
      end

      dialog
    end

    # @param [Hash] selected
    def add_extension_sources(selected)
      @logger.debug { "#{self.class.object_name} add_extension_sources (#{selected.size})" }
      selected.each { |item|
        extension_sources_manager.add(item[:path], enabled: item[:enabled])
      }
      nil
    end

    # @param [ExtensionSourcesManager::ImportError] error
    def handle_import_error(error)
      message = case error
      when ExtensionSourcesManager::IncompatibleFileVersion
        @logger.debug { error.message }
        'The extension sources file is newer than what can be read, please update Extension Sources to the latest version.'
      when ExtensionSourcesManager::ImportError
        "The extension sources file could not be read due to an error:\n\n#{error.message}"
      else
        raise error
      end
      # Defer the execution in order to not block SketchUp's startup sequence.
      Execution.defer do
        @system.ui.messagebox(message)
      end
    end

    # @return [ExtensionStatisticsDialog]
    def extension_statistics_dialog
      @extension_statistics_dialog ||= create_extension_statistics_dialog
      @extension_statistics_dialog
    end

    # @return [ExtensionStatisticsDialog]
    def create_extension_statistics_dialog
      dialog = ExtensionStatisticsDialog.new
      dialog.error_handler = error_handler

      dialog.on(:boot) do |dialog|
        dialog.update(dialog.report)
      end

      dialog.on(:accept) do |dialog, selected|
        dialog.close
        # add_extension_sources(selected)
      end

      dialog.on(:cancel) do |dialog|
        dialog.close
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
      File.join(@system.os.app_data_path, 'CookieWare', 'Extension Source Manager')
    end

    # The absolute path where the manager will serialize to/from.
    #
    # @return [String]
    def sources_json_path
      File.join(storage_dir, EXTENSION_SOURCES_JSON)
    end

    # The absolute path where the timing logs will be stored.
    #
    # @return [String]
    def timing_log_path
      File.join(storage_dir, EXTENSIONS_TIMING_LOG)
    end

    # ExtensionSourcesScanner debug methods:
    # The scanner can take some time to complete. In order to speed up
    # development iteration, some debug methods can be used to read/write a
    # cache of scanned results.

    # @return [String]
    def debug_scan_dump_path
      debug_path = File.expand_path('../../../fixtures/scan.json', __dir__) # rubocop:disable SketchupSuggestions/FileEncoding
    end

    # @param [String] json_path
    # @return [Array<Hash>]
    def debug_read_scan_dump(json_path)
      @logger.debug { "#{self.class.object_name} debug_read_scan_dump" }
      json = File.open(json_path, "r:UTF-8", &:read)
      data = JSON.parse(json, symbolize_names: true)
      results = data.map { |item|
        ExtensionSource.new(path: item[:path], enabled: item[:enabled]).to_hash
      }
    end

    # @param [String] json_path
    # @param [Array<Hash>] results
    def debug_write_scan_dump(json_path, results)
      @logger.debug { "#{self.class.object_name} debug_write_scan_dump" }
      json = JSON.pretty_generate(results.map(&:to_hash))
      File.open(json_path, "w:UTF-8") { |file| file.write(json) }
      nil
    end

  end # class
end # module
