module TT::Plugins::ExtensionSources
  # A dialog the user interacts with to manage additional load-paths.
  class ExtensionSourcesDialog

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
      ]
      @events = setup_events(event_names)
      @dialog = create_dialog
    end

    # @param [Symbol] event
    def on(event, &block)
      raise "unknown event: #{event}" unless @events.key?(event)

      @events[event] << block
    end

    # @param [Array<ExtensionSource>] sources
    def update(sources)
      call_js('app.update', sources)
    end

    # @return [nil]
    def bring_to_front
      @dialog.bring_to_front
    end

    # @return [nil]
    def show
      visible? ? bring_to_front : init_and_show
      nil
    end

    # @return [Boolean]
    def close
      if @dialog.visible?
        @dialog.close
        return true
      end
      false
    end

    def visible?
      @dialog.visible?
    end

    # @return [Boolean] The resulting visibility state.
    def toggle
      visible? ? close : show
      visible?
    end

    private

    # @param [Array<Symbol>] event_names
    # @return [Hash]
    def setup_events(event_names)
      Hash[event_names.map { |key| [key, []] }]
    end

    def init_and_show
      raise "don't initialize if dialog is shown" if @dialog.visible?

      init_action_callbacks(@dialog)
      @dialog.show
    end

    # @param [String] function
    # @param [Array<#to_json>] args
    def call_js(function, *args)
      params = args.map(&:to_json).join(',')
      @dialog.execute_script("app.update(#{params})")
      nil
    end

    # @param [Symbol] event
    def trigger(event, *args)
      raise "unknown event: #{event}" unless @events.key?(event)
      warn "event without listeners: #{event}" if @events[event].empty?

      @events[event].each { |callback| callback.call(*args) }
    end

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
    end

    # @return [String]
    def ui_path
      path = __dir__
      path.force_encoding('utf-8')
      File.join(path, 'ui')
    end

  end

end #module
