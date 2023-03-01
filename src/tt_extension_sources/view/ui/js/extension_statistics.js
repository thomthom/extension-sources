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
    mousedown_index: null,
    last_selected_index: null,
    sources: [],
    report: [],
  },
  computed: {
    is_filtered() {
      return this.filter.length != 0;
    },
    filtered_sources() {
      if (!this.is_filtered) {
        return this.sources;
      }
      const upper_case_filter = this.filter.toUpperCase();
      return this.sources.filter((source) => {
        const upper_case_path = source.path.toUpperCase();
        return upper_case_path.includes(upper_case_filter);
      });
    },
    filtered_source_ids() {
      return this.filtered_sources.map(source => source.source_id);
    },
    selected() {
      return this.sources.filter((source) => {
        return source.selected;
      });
    },
    filtered_chart_data() {
      const paths = Object.keys(this.report);
      console.log('paths', paths);

      // TODO: Improve. Might not be a single common prefix.
      const common_prefix = this.longest_common_prefix(paths);
      const pattern = new RegExp(`^${common_prefix}`, 'i');
      const labels = paths.map(x => x.replace(pattern, ''));
      console.log('labels', labels);

      // const data = labels.map(x => 2);
      // https://stackoverflow.com/a/14810722/486990
      const objectMap = (obj, fn) =>
        Object.fromEntries(
          Object.entries(obj).map(
            ([k, v], i) => [k, fn(v, k, i)]
          )
        );
      const max_range = 1.2;
      const data = objectMap(this.report, (v, path, i) => {
        // TODO:
        // return Object.values(path)[0].mean;
        const row = Object.values(v)[0];
        return {
          path: path,
          min: row.min,
          max: row.max,
          mean: row.mean,
          median: row.median,
          row: row,

          label: path.replace(pattern, ''),
          left: (row.min / max_range) * 100,
          width: ((row.max / max_range) - (row.min / max_range)) * 100,

          mean_left: (row.mean / max_range) * 100,
          median_left: (row.median / max_range) * 100,
        };
      });
      console.log('data', data);
      return data;
    }
  },
  methods: {
    source_enabled_id(source_id) {
      return `sourceEnabled${source_id}`;
    },
    clear_filter() {
      this.filter = "";
    },
    update(report) {
      console.log('update...');
      console.log(report);
      this.report = report;
      this.update_chart();
    },
    enable_toggle(source) {
      // console.log('enable_toggle', source.enabled);
      // Check clicked toggle have already changed state. This handler will
      // apply the same state to the whole selection.
      const enabled = source.enabled;
      for (let item of this.selected) {
        item.enabled = enabled;
      }
    },
    trace(message) {
      console.log(message);
    },
    can_select(source_id) {
      if (!this.is_filtered) return true;
      return this.filtered_source_ids.includes(source_id);
    },
    select(event, source, index) {
      if (event.buttons != MouseButtons.primary) {
        // console.log('select', 'not primary buttons', event.buttons)
        return;
      }
      // console.log('select', source, source.source_id, 'selected:', source.selected, event);
      this.mousedown_index = index;
      // Clear existing selection unless Ctrl is pressed.
      const addKey = OS.isMac ? event.metaKey : event.ctrlKey;
      if (!addKey) {
        // console.log('> clear-select');
        for (const item of this.sources) {
          item.selected = false;
        }
      }
      if (event.shiftKey && this.last_selected_index !== null) {
        // console.log('> multi-select', app.filtered_source_ids);
        const min = Math.min(this.last_selected_index, index);
        const max = Math.max(this.last_selected_index, index);
        for (let i = min; i <= max; ++i) {
          this.filtered_sources[i].selected = true;
        }
      } else {
        // console.log('> single-select');
        source.selected = !source.selected;
      }
      this.last_selected_index = index;
    },
    drag_select(event, source, index) {
      if (event.buttons != MouseButtons.primary) {
        return;
      }
      if (this.last_selected_index == index) {
        return;
      }
      // console.log('drag_select', source, source.source_id, 'selected:', source.selected, event);
      const toggleKey = OS.isMac ? event.metaKey : event.ctrlKey;
      if (toggleKey) {
        // console.log('> toggle');
        source.selected = !source.selected;
      } else {
        // console.log('> range');
        // console.log(this.filtered_source_ids);
        const min = Math.min(this.mousedown_index, index);
        const max = Math.max(this.mousedown_index, index);
        const selectable_ids = this.filtered_source_ids.slice(min, max + 1);
        // console.log(index, min, max, selectable_ids);
        for (let item of this.sources) {
          if (selectable_ids.includes(item.source_id)) {
            item.selected = true;
          } else {
            item.selected = false;
          }
        }
      }
      this.last_selected_index = index;
    },
    accept() {
      sketchup.accept(this.selected);
    },
    cancel() {
      sketchup.cancel();
    },
    on_source_changed(source_id, changes) {
      console.log('on_source_changed', source_id, changes)
      sketchup.source_changed(source_id, changes);
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
      a.sort();

      /* find the minimum length from first and last string */
      let end = Math.min(a[0].length, a[size - 1].length);

      /* find the common prefix between the first and
         last string */
      let i = 0;
      while (i < end && a[0][i] == a[size - 1][i])
        i++;

      let pre = a[0].substring(0, i);
      return pre;
    },
    create_chart() {
      const ctx = document.getElementById('chart');

      new Chart(ctx, {
        type: 'bar',
        data: {
          labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
          datasets: [{
            label: '# of Votes',
            data: [12, 19, 3, 5, 2, 3],
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          scales: {
            y: {
              beginAtZero: true
            }
          }
        }
      });
    },
    update_chart() {
      const ctx = document.getElementById('chart');

      const paths = Object.keys(this.report);

      // TODO: Improve. Might not be a single common prefix.
      const common_prefix = this.longest_common_prefix(paths);
      const pattern = new RegExp(`^${common_prefix}`, 'i');
      const labels = paths.map(x => x.replace(pattern, ''));
      console.log('labels', labels);

      // const data = labels.map(x => 2);
      // https://stackoverflow.com/a/14810722/486990
      const objectMap = (obj, fn) =>
        Object.fromEntries(
          Object.entries(obj).map(
            ([k, v], i) => [k, fn(v, k, i)]
          )
        );
      const data = objectMap(this.report, path => {
        // TODO:
        return Object.values(path)[0].mean;
      });
      console.log('data', data);

      new Chart(ctx, {
        type: 'bar',
        data: {
          // labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
          labels: labels,
          datasets: [{
            label: 'Extension load time (seconds)',
            // data: [12, 19, 3, 5, 2, 3],
            data: data,
            borderWidth: 1
          }]
        },
        options: {
          responsive: true,
          scales: {
            y: {
              beginAtZero: true
            }
          }
        }
      });
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

    // this.create_chart(); // TODO: debug

    // Everything ready, notify the Ruby side.
    sketchup.ready();
  },
});
