require 'tt_extension_sources/view/dialog'

module TT::Plugins::ExtensionSources
  # A dialog the user interacts with to manage additional load-paths.
  class ExtensionSourcesDialog < Dialog

    def initialize
      event_names = [
        :boot,
        :options,
        :undo,
        :redo,
        :scan_paths,
        :import_paths,
        :export_paths,
        :add_path,
        :edit_path,
        :remove_path,
        :reload_path,
        :reorder,
        :source_changed,
        :sources_changed,
      ]
      super(event_names)
    end

    # @param [Array<ExtensionSource>] sources
    def update(sources)
      call_js('app.update', sources)
    end

    private

    # @return [UI::HtmlDialog]
    def create_dialog
      dialog = UI::HtmlDialog.new(
      {
        dialog_title: 'Extension Sources',
        preferences_key: 'TT_ExtensionSourcesDialog',
        scrollable: false,
        resizable: true,
        width: 600,
        height: 400,
        left: 100,
        top: 100,
        min_width: 400,
        min_height: 200,
        style: UI::HtmlDialog::STYLE_DIALOG,
      })
      html_file = File.join(ui_path, 'html', 'extension_sources.html')
      dialog.set_file(html_file)
      dialog
    end

    # @param [UI::HtmlDialog] dialog
    def init_action_callbacks(dialog)
      dialog.add_action_callback('ready') do
        trigger(:boot, self)
      end
      dialog.add_action_callback('options') do
        trigger(:options, self)
      end
      dialog.add_action_callback('undo') do
        trigger(:undo, self)
      end
      dialog.add_action_callback('redo') do
        trigger(:redo, self)
      end
      dialog.add_action_callback('scan_paths') do
        trigger(:scan_paths, self)
      end
      dialog.add_action_callback('import_paths') do
        trigger(:import_paths, self)
      end
      dialog.add_action_callback('export_paths') do
        trigger(:export_paths, self)
      end
      dialog.add_action_callback('add_path') do
        trigger(:add_path, self)
      end
      dialog.add_action_callback('edit_path') do |context, source_id|
        trigger(:edit_path, self, source_id.to_i) # JS returns Float.
      end
      dialog.add_action_callback('remove_path') do |context, source_id|
        trigger(:remove_path, self, source_id.to_i) # JS returns Float.
      end
      dialog.add_action_callback('reload_path') do |context, source_id|
        trigger(:reload_path, self, source_id.to_i) # JS returns Float.
      end
      dialog.add_action_callback('reorder') do |context, selected_ids, target_id, before|
        selected_ids.map!(&:to_i) # JS returns Float.
        trigger(:reorder, self, selected_ids, target_id.to_i, before) # JS returns Float.
      end
      dialog.add_action_callback('source_changed') do |context, source_id, changes|
        trigger(:source_changed, self, source_id.to_i, changes) # JS returns Float.
      end
      dialog.add_action_callback('sources_changed') do |context, changes|
        changes.map! { |change|
          # change: { source_id: 123, properties: { enabled: true } }
          symbolize_keys!(change)
          change[:source_id] = change[:source_id].to_i # JS returns Float.
          symbolize_keys!(change[:properties])
          change
        }
        trigger(:sources_changed, self, changes)
      end
    end

    # @param [Hash] hash
    # @return [Hash]
    def symbolize_keys!(hash)
      if hash.respond_to?(:transform_keys!)
        hash.transform_keys!(&:to_sym) # Ruby 2.5
      else
        temp = Hash[hash.map { |k, v| [k.to_sym, v] }]
        hash.clear
        hash.merge!(temp)
      end
      hash
    end

  end

end #module
