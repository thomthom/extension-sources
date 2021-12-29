require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/extension_sources_dialog'
require 'tt_extension_sources/extension_sources_manager'

module TT::Plugins::ExtensionSources
  class ExtensionSourcesController

    def initialize
      @extension_sources_manager = nil
      @extension_sources_dialog = nil
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

    private

    # @param [ExtensionSourcesDialog] dialog
    def add_path(dialog)
      path = UI.select_directory(title: "Select Extension Source Directory")
      return if path.nil?

      return unless extension_sources_manager.add(path)

      sync_dialog(dialog)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [String] path_id
    def edit_path(dialog, path_id)
      source = extension_sources_manager.find_by_path_id(path_id)
      raise "found no source path for: #{path_id}" if source.nil?

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

      # TODO: Use notifications on ExtensionSource to manage updates?
      return unless extension_sources_manager.update(path_id: path_id, path: path)

      sync_dialog(dialog)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [String] path_id
    def remove_path(dialog, path_id)
      source = extension_sources_manager.remove(path_id)
      raise "found no source path for: #{path_id}" if source.nil?

      sync_dialog(dialog)
    end

    # @param [ExtensionSourcesDialog] dialog
    # @param [String] path_id
    def reload_path(dialog, path_id)
      puts "reload_path(#{path_id})"

      source = extension_sources_manager.find_by_path_id(path_id)
      raise "found no source path for: #{path_id}" if source.nil?

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

    # @return [ExtensionSourcesManager]
    def extension_sources_manager
      @extension_sources_manager ||= ExtensionSourcesManager.new
      @extension_sources_manager
    end

    # @return [ExtensionSourcesDialog]
    def extension_sources_dialog
      @extension_sources_dialog ||= ExtensionSourcesDialog.new
      @extension_sources_dialog
    end

    def sync_dialog(dialog)
      # TODO: Use events to update dialog when manager changes. (Bulk updates?)
      sources = extension_sources_manager.sources
      dialog.update(sources)
      nil
    end

  end # class
end # module