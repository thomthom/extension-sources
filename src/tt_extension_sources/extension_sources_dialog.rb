module TT::Plugins::ExtensionSources

  class ExtensionSourcesDialog

    def initialize
      @dialog = create_dialog
    end

    def show
      @dialog.visible? ? @dialog.bring_to_front : @dialog.show
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

    # @return  [UI::HtmlDialog]
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

    # @return [String]
    def ui_path
      path = __dir__
      path.force_encoding('utf-8')
      File.join(path, 'ui')
    end

  end

end #module
