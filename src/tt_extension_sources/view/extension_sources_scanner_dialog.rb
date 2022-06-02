require 'tt_extension_sources/view/dialog'

module TT::Plugins::ExtensionSources
  # A dialog the user interacts with to manage additional load-paths.
  class ExtensionSourcesScannerDialog < Dialog

    attr_reader :sources

    def initialize
      event_names = [
        :boot,
        :accept,
        :cancel,
      ]
      super(event_names)
      @sources = []
    end

    # @param [Array<ExtensionSource>] sources
    def update(sources)
      call_js('app.update', sources)
    end

    # @param [Array<ExtensionSource>] sources
    def show(sources)
      @sources = sources
      super()
    end

    # @api private
    def toggle
      # Cannot do `private :toggle` because that makes the method on the
      # superclass private, affecting all subclasses.
      raise RuntimeError, 'Not a valid action for this dialog.'
    end

    private

    # @return [UI::HtmlDialog]
    def create_dialog
      dialog = UI::HtmlDialog.new(
      {
        dialog_title: 'Scan for Extension Sources',
        preferences_key: 'TT_ExtensionSourcesScannerDialog',
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
      html_file = File.join(ui_path, 'html', 'extension_sources_scanner.html')
      dialog.set_file(html_file)
      dialog
    end

    # @param [UI::HtmlDialog] dialog
    def init_action_callbacks(dialog)
      dialog.add_action_callback('ready') do
        trigger(:boot, self)
      end
      dialog.add_action_callback('accept') do |context, selected|
        trigger(:accept, self, symbolize_keys(selected))
      end
      dialog.add_action_callback('cancel') do
        trigger(:cancel, self)
      end
    end

  end

end #module
