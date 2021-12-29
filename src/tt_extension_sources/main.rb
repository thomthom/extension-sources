require 'sketchup.rb'

require 'json'

require 'tt_extension_sources/debug'
require 'tt_extension_sources/extension_source'
require 'tt_extension_sources/extension_sources_dialog'
require 'tt_extension_sources/extension_sources_manager'

module TT::Plugins::ExtensionSources

  # * Track startup timings. Keep raw log. Keep separate cache of average.
  # * Reload function.
  # * Reorder source paths.
  # * Import/export function.
  # * Undo/redo function.

  def self.sync_dialog(dialog)
    # TODO: Use events to update dialog when manager changes. (Bulk updates?)
    sources = self.extension_sources_manager.sources
    dialog.update(sources)
    nil
  end

  # @param [ExtensionSourcesDialog] dialog
  def self.add_path(dialog)
    path = UI.select_directory(title: "Select Extension Source Directory")
    return if path.nil?

    return unless self.extension_sources_manager.add(path)

    self.sync_dialog(dialog)
  end

  # @param [ExtensionSourcesDialog] dialog
  # @param [String] path_id
  def self.edit_path(dialog, path_id)
    source = self.extension_sources_manager.find_by_path_id(path_id)
    raise "found no source path for: #{path_id}" if source.nil?

    title = "Select Extension Source Directory"
    path = loop do
      path = UI.select_directory(title: title, directory: source.path)
      return if path.nil?

      if self.extension_sources_manager.include_path?(path)
        message = "Source path '#{path}' already exists. Choose a different path?"
        result = UI.messagebox(message, MB_OKCANCEL)
        next if result == IDOK

        return
      end

      break path
    end

    # TODO: Use notifications on ExtensionSource to manage updates?
    return unless self.extension_sources_manager.update(path_id: path_id, path: path)

    self.sync_dialog(dialog)
  end

  # @param [ExtensionSourcesDialog] dialog
  # @param [String] path_id
  def self.remove_path(dialog, path_id)
    source = self.extension_sources_manager.remove(path_id)
    raise "found no source path for: #{path_id}" if source.nil?

    self.sync_dialog(dialog)
  end

  # @param [ExtensionSourcesDialog] dialog
  # @param [String] path_id
  def self.reload_path(dialog, path_id)
    puts "reload_path(#{path_id})"

    source = self.extension_sources_manager.find_by_path_id(path_id)
    raise "found no source path for: #{path_id}" if source.nil?

    puts "> path: #{source.path}"

    pattern = "#{source.path}/**/*.rb"
    Dir.glob(pattern) { |path|
      puts "  > #{path}"
      # TODO: try/rescue -> report errors (Open Ruby Console)
      # load path
    }
  end

  # @return [ExtensionSourcesManager]
  def self.extension_sources_manager
    @extension_sources_manager ||= ExtensionSourcesManager.new
    @extension_sources_manager
  end

  # @return [ExtensionSourcesDialog]
  def self.open_extension_sources_dialog
    @extension_sources_dialog ||= ExtensionSourcesDialog.new

    @extension_sources_dialog.on(:boot) do |dialog|
      sources = self.extension_sources_manager.sources
      dialog.update(sources)
    end

    @extension_sources_dialog.on(:add_path) do |dialog|
      self.add_path(dialog)
    end

    @extension_sources_dialog.on(:edit_path) do |dialog, path|
      self.edit_path(dialog, path)
    end

    @extension_sources_dialog.on(:remove_path) do |dialog, path|
      self.remove_path(dialog, path)
    end

    @extension_sources_dialog.on(:reload_path) do |dialog, path|
      self.reload_path(dialog, path)
    end

    @extension_sources_dialog.show
    @extension_sources_dialog
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
