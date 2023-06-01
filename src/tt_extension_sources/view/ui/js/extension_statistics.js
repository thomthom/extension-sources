// https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/buttons
const MouseButtons = {
  none: 0,      // No button or un- initialized
  primary: 1,   // Primary button(usually the left button)
  secondary: 2, // Secondary button(usually the right button)
  auxiliary: 4, // Auxiliary button(usually the mouse wheel button or middle button)
  fourth: 8,    // 4th button(typically the "Browser Back" button)
  fifth: 16,    // 5th button(typically the "Browser Forward" button)
};

const OS = {
  isMac: navigator.platform.toUpperCase().indexOf('MAC') >= 0,
};

// src/tt_extension_sources/model/statistics_reporter.rb
const GroupBy = {
  major: 1,
  major_minor: 2,
  major_minor_patch: 3,
};

const SortBy = {
  median: 'median',
  mean: 'mean',
  min: 'min',
  max: 'max',
};

const FilterByNone = "None";

let app = new Vue({
  el: '#app',
  data: {
    groupBy: GroupBy.major_minor_patch,
    // Median is a good default accounting for outliers due to load errors
    // that could impact the extension load time.
    sortBy: SortBy.median, // TODO: Persist option.
    sortAscending: false, // TODO: Persist option.
    filterBy: FilterByNone, // SketchUp version filter.
    filter: "", // Path filter.
    report: [],
  },
  computed: {
    is_filtered() {
      return this.filter.length != 0;
    },
    filtered_paths() {
      if (!this.is_filtered) {
        return Object.keys(this.report);
      }
      const upper_case_filter = this.filter.toUpperCase();
      return Object.keys(this.report).filter(path => {
        const upper_case_path = path.toUpperCase();
        return upper_case_path.includes(upper_case_filter);
      });
    },
    /** @return {Array<string>} */
    sorted_filtered_paths() {
      // TODO: Filter on label (sans common prefix?)
      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/Collator#options
      return this.filtered_paths.sort(
        (a, b) => a.localeCompare(b, undefined, { sensitivity: 'accent' }));
    },
    filter_by_options() {
      let versions = new Set;
      for (item of Object.values(this.report)) {
        for (version of Object.keys(item.versions)) {
          versions.add(version);
        }
      }
      // console.log('filter_by_options', versions);
      return Array.from(versions).sort((a, b) => b - a);
    },
    sort_by_label() {
      switch (this.sortBy) {
        case SortBy.median: return 'Median';
        case SortBy.mean: return 'Mean';
        case SortBy.min: return 'Min';
        case SortBy.max: return 'Max';
      }
    },
    filtered_chart_data() {
      const paths = this.sorted_filtered_paths;
      // console.log('paths', paths);

      const common_prefix = this.longest_common_prefix(Object.keys(this.report));
      const pattern = new RegExp(`^${common_prefix}`, 'i');
      // const labels = paths.map(x => x.replace(pattern, ''));
      // console.log('labels', labels);

      const max_range = Math.max(...Object.values(this.report).map(item => item.total.max))

      let data = [];
      for (path of paths) {
        // console.log(`> path: ${path}`);

        const item = this.report[path];
        // console.log(`> item:`, item, Object.values(item));

        // Sort the data for the SketchUp versions by the version number.
        let versions = Object.keys(item.versions).map(version => {
          let version_data = this.graph_data(item.versions[version], max_range);
          version_data.version = version;
          return version_data;
        });
        versions.sort((a, b) => b.values.median - a.values.median);

        data.push({
          reactive: item, // Access to reactive properties.
          path: path,
          label: path.replace(pattern, ''),
          total: this.graph_data(item.total, max_range),
          versions: versions,
        });
      }

      if (this.sortAscending) {
        data.sort((a, b) => a.total.values[this.sortBy] - b.total.values[this.sortBy]);
      } else {
        data.sort((a, b) => b.total.values[this.sortBy] - a.total.values[this.sortBy]);
      }

      return data;
    }
  },
  methods: {
    clear_filter() {
      this.filter = "";
    },
    graph_data(row, max_range) {
      return {
        values: row,
        styles: {
          minmax: {
            left: `${(row.min / max_range) * 100}%`,
            width: `${((row.max / max_range) - (row.min / max_range)) * 100}%`,
          },
          mean: {
            left: `${(row.mean / max_range) * 100}%`,
          },
          median: {
            left: `${(row.median / max_range) * 100}%`,
          },
        },
      };
    },
    update(report, group_by, filter_by) {
      console.log('update', `group_by: ${group_by}`, `filter_by: ${filter_by}`);
      console.log(report);
      this.groupBy = group_by;
      // Inject properties before assigning to Vue data so they become reactive.
      // Note: These are lost when updating Group By, but for now that's ok.
      //       It's not something that's expected to be done frequently.
      for (const [_key, value] of Object.entries(report)) {
        value.showVersions = false
      }
      this.report = report;

      const app = this;
      const filter = (filter_by === null) ? 'None' : filter_by[0];
      this.$nextTick(() => {
        // console.log('nextTick', filter);
        app.filterBy = filter;
      });
    },
    on_group_by_change(event) {
      console.log('on_group_by_change', event, event.target.value);
      sketchup.group_by(event.target.value);
    },
    on_filter_by_change(event) {
      console.log('on_filter_by_change', event, event.target.value);
      let filter_by = event.target.value;
      filter_by = (filter_by == FilterByNone) ? null : [filter_by]
      sketchup.filter_by(filter_by);
    },
    trace(message) {
      console.log(message);
    },
    cancel() {
      sketchup.cancel();
    },
    /** @param {Array<string>} strings */
    longest_common_prefix(strings) {
      // https://www.geeksforgeeks.org/longest-common-prefix-using-sorting/
      let num_strings = strings.length;

      if (num_strings == 0)
        return '';

      if (num_strings == 1)
        return strings[0];

      const sorted = [...strings].sort(); // https://stackoverflow.com/a/42442909/486990

      // Find the minimum length from first and last string.
      let end = Math.min(sorted[0].length, sorted[num_strings - 1].length);

      // Find the common prefix between the first and last string.
      let i = 0;
      while (i < end && sorted[0][i] == sorted[num_strings - 1][i])
        i++;

      let prefix = sorted[0].substring(0, i);
      return prefix;
    }
  },
  mounted() {
    // Disable the context menu, except on input elements.
    document.addEventListener('contextmenu', (event) => {
      console.log('contextmenu', event);
      const debug_mode = event.ctrlKey && event.shiftKey;
      const elements_allowed_context_menu =
        'input[type=text], input[type=search], textarea';
      if (!debug_mode && !event.target.matches(elements_allowed_context_menu)) {
        event.preventDefault();
      }
    });

    // Everything ready, notify the Ruby side.
    sketchup.ready();
  },
});
