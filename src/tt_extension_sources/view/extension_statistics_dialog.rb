require 'tt_extension_sources/view/dialog'

# TODO: Pass in from controller.
require 'tt_extension_sources/model/statistics_csv'
require 'tt_extension_sources/model/statistics_reporter'

module TT::Plugins::ExtensionSources
  # A dialog displaying statistics for the managed extensions.
  class ExtensionStatisticsDialog < Dialog

    attr_reader :report

    def initialize
      event_names = [
        :boot,
        :accept,
        :cancel,
      ]
      super(event_names)
      @report = []
    end

    # @param [Hash] report
    def update(report)
      call_js('app.update', report)
    end

    # @param [Hash] _report
    def show(_report)
      # TODO: Pass in stats.

      app_data = File.join(OS.app_data_path, 'CookieWare', 'Extension Source Manager')
      timing_log_path = File.join(app_data, 'extension-sources-timings.csv')
      puts timing_log_path

      records = []
      File.open(timing_log_path, 'r:UTF-8') { |file|
        statistics = StatisticsCSV.new(io: file)
        records = statistics.read
      }
      puts "Records: #{records.size}"

      reporter = StatisticsReporter.new
      report = reporter.report(records)
      puts "Report: #{report.size}"

      @report = report
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
        dialog_title: 'Extension Statistics',
        preferences_key: 'TT_ExtensionSourcesStatisticsDialog',
        scrollable: false,
        resizable: true,
        width: 900,
        height: 600,
        left: 150,
        top: 150,
        min_width: 400,
        min_height: 200,
        style: UI::HtmlDialog::STYLE_DIALOG,
      })
      html_file = File.join(ui_path, 'html', 'extension_statistics.html')
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
