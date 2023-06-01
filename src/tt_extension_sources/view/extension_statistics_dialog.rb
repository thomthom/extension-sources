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
        :group_by,
        :filter_by,
      ]
      super(event_names)
      @report = [] # TODO: Move to controller.
      @group_by = StatisticsReporter::GROUP_BY_MAJOR_MINOR # TODO: Move to controller.
      @filter = nil # TODO: Move to controller.
    end

    # @param [Hash] report
    def update(report, group_by: StatisticsReporter::GROUP_BY_MAJOR_MINOR, filter: nil)
      call_js('app.update', report, group_by, filter)
    end

    # @param [Hash] _report
    def show(_report)
      # TODO: Pass in stats from controller.
      @report = generate_report(group_by: @group_by, filter: @filter)
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
      on(:group_by) { |_dialog, value| update_group_by(value) } # TODO: Should be done by controller.
      on(:filter_by) { |_dialog, value| update_filter_by(value) } # TODO: Should be done by controller.
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
      dialog.add_action_callback('group_by') do |context, value|
        trigger(:group_by, self, value.to_i)
      end
      dialog.add_action_callback('filter_by') do |context, versions|
        trigger(:filter_by, self, versions)
      end
    end

    # TODO: This should be handled by controller.
    def update_group_by(group_by)
      @report = generate_report(group_by: group_by, filter: @filter)
      @group_by = group_by
      update(@report, group_by: group_by, filter: @filter)
    end

    # TODO: This should be handled by controller.
    def update_filter_by(filter_by)
      p [:update_filter_by, filter_by]
      @report = generate_report(group_by: @group_by, filter: filter_by)
      @filter_by = filter_by
      update(@report, group_by: @group_by, filter: filter_by)
    end

    # @param [Integer] group_by One of `GROUP_BY_*` values in {StatisticsReporter::Constants}.
    def generate_report(group_by: StatisticsReporter::GROUP_BY_MAJOR_MINOR, filter: nil)
      app_data = File.join(OS.app_data_path, 'CookieWare', 'Extension Source Manager')
      timing_log_path = File.join(app_data, 'extension-sources-timings.csv')
      puts timing_log_path

      records = []
      File.open(timing_log_path, 'r:UTF-8') { |file|
        statistics = StatisticsCSV.new(io: file)
        records = statistics.read
      }
      puts "Records: #{records.size} (Grouped by: #{group_by}, Filtered by: #{filter.inspect})"

      reporter = StatisticsReporter.new
      report = reporter.report(records, group_by: group_by, filters: filter)
      puts "Report: #{report.size}"

      report
    end

  end

end #module
