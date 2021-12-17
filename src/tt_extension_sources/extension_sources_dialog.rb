module TT::Plugins::ExtensionSources

  class ExtensionSourcesDialog

    def initialize
      @events = {
        boot: [],
      }
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

    def bring_to_front
      @dialog.bring_to_front
    end

    def show
      visible? ? bring_to_front : init_and_show
      nil
    end

    def close
      @dialog.close
      nil
    end

    # @param [Boolean]
    def visible?
      @dialog.visible?
    end

    def toggle
      visible? ? close : show
      visible?
    end

    private

    def init_and_show
      raise "don't initialize if dialog is shown" if @dialog.visible?

      init_action_callbacks(@dialog)
      @dialog.show
    end

    # @param [String] function
    # @param [Array<#to_json>] params
    def call_js(function, *args)
      params = args.map(&:to_json).join(',')
      @dialog.execute_script("app.update(#{params})")
      nil
    end

    # @param [Symbol] event
    def trigger(event, *args)
      raise "unknown event: #{event}" unless @events.key?(event)

      @events[event].each { |callback| callback.call(*args) }
    end

    # @return [UI::HtmlDialog]
    def create_dialog
      dialog = UI::HtmlDialog.new(
      {
        dialog_title: 'Extension Sources',
        preferences_key: 'TT_ExtensionSourcesDialog',
        scrollable: true,
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
    end

    # @return [String]
    def ui_path
      path = __dir__
      path.force_encoding('utf-8')
      File.join(path, 'ui')
    end

  end

end #module