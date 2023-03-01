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

let app = new Vue({
  el: '#app',
  data: {
    filter: "",
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
    sorted_filtered_paths() {
      // TODO: Sort by user options.
      // TODO: Filter on label (sans common prefix?)
      // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/Collator/Collator#options
      return this.filtered_paths.sort(
        (a, b) => a.localeCompare(b, undefined, { sensitivity: 'accent' }));
    },
    filtered_chart_data() {
      const paths = this.sorted_filtered_paths;
      console.log('paths', paths);

      // TODO: Improve. Might not be a single common prefix.
      // TODO: Account for only one item.
      const common_prefix = this.longest_common_prefix(Object.keys(this.report));
      const pattern = new RegExp(`^${common_prefix}`, 'i');
      // const labels = paths.map(x => x.replace(pattern, ''));
      // console.log('labels', labels);

      const max_range = 1.2; // TODO: Compute max range.
      let data = [];
      for (path of paths) {
        // console.log(`> path: ${path}`);

        const item = this.report[path];
        // console.log(`> item:`, item, Object.values(item));

        // TODO: Compute for all (filtered) SketchUp versions.
        const row = Object.values(item)[0];
        // console.log(`> row:`, row);

        data.push({
          path: path,
          // values: row,
          min: row.min,
          max: row.max,
          mean: row.mean,
          median: row.median,

          label: path.replace(pattern, ''),

          // TODO: Make style objects.
          left: (row.min / max_range) * 100,
          width: ((row.max / max_range) - (row.min / max_range)) * 100,

          mean_left: (row.mean / max_range) * 100,
          median_left: (row.median / max_range) * 100,
        });
      }
      // console.log('data', data);

      // TODO: Sort by user config. Ascending/descending.
      // Median is a good default accounting for outliers due to load errors
      // that could impact the extension load time.
      // TODO: Don't record load time when extension is disabled.
      // TODO: Don't record load time if require reports errors.
      data.sort((a, b) => b.median - a.median);

      return data;
    }
  },
  methods: {
    clear_filter() {
      this.filter = "";
    },
    update(report) {
      console.log('update...');
      console.log(report);
      this.report = report;
    },
    trace(message) {
      console.log(message);
    },
    cancel() {
      sketchup.cancel();
    },
    // https://www.geeksforgeeks.org/longest-common-prefix-using-sorting/
    longest_common_prefix(a) {
      let size = a.length;

      /* if size is 0, return empty string */
      if (size == 0)
        return "";

      if (size == 1)
        return a[0];

      /* sort the array of strings */
      // a.sort();
      const s = [...a].sort(); // https://stackoverflow.com/a/42442909/486990

      /* find the minimum length from first and last string */
      let end = Math.min(s[0].length, s[size - 1].length);

      /* find the common prefix between the first and
         last string */
      let i = 0;
      while (i < end && s[0][i] == s[size - 1][i])
        i++;

      let pre = s[0].substring(0, i);
      return pre;
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
