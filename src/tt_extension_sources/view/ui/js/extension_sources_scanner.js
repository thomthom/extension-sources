// https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/buttons
const MouseKeys = {
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
    }
  },
  methods: {
    source_enabled_id(source_id) {
      return `sourceEnabled${source_id}`;
    },
    clear_filter() {
      this.filter = "";
    },
    update(sources) {
      // Inject additional properties that only the Vue app cares about.
      // For Vue's reactor to pick up the changes they must be added to
      // the `sources` data before assigning to the Vue app's data.
      for (const item of sources) {
        item.selected = false;
      }
      this.sources = sources;
    },
    enable_toggle(source) {
      // console.log('enable_toggle', source.enabled);
      const enabled = source.enabled;
      for (let item of this.selected) {
        item.enabled = enabled;
      }
    },
    can_select(source_id) {
      if (!this.is_filtered) return true;
      return this.filtered_source_ids.includes(source_id);
    },
    select(event, source, index) {
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
      if (event.buttons != MouseKeys.primary) {
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
    }
  },
  mounted() {
    sketchup.ready();
  },
});
