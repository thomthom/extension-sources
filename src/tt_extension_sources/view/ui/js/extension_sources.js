// https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/buttons
const MouseButtons = {
  none: 0,      // No button or un- initialized
  primary: 1,   // Primary button(usually the left button)
  secondary: 2, // Secondary button(usually the right button)
  auxiliary: 4, // Auxiliary button(usually the mouse wheel button or middle button)
  fourth: 8,    // 4th button(typically the "Browser Back" button)
  fifth: 16,    // 5th button(typically the "Browser Forward" button)
};

// https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/button
const MouseButton = {
  primary: 0,   // Primary button(usually the left button)
  auxiliary: 1, // Auxiliary button(usually the mouse wheel button or middle button)
  secondary: 2, // Secondary button(usually the right button)
  fourth: 3,    // 4th button(typically the "Browser Back" button)
  fifth: 4,     // 5th button(typically the "Browser Forward" button)
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
    drag_over_source_id: null,
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
      let ui_state = {};
      for (const item of this.sources) {
        ui_state[item.source_id] = { selected: item.selected };
      }
      for (const item of sources) {
        item.selected = ui_state[item.source_id]?.selected || false;
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
    // --- Selection Logic ---
    can_select(source_id) {
      if (!this.is_filtered) return true;
      return this.filtered_source_ids.includes(source_id);
    },
    // Returns an object describing the selection behaviour.
    select_behavior(event) {
      const toggle_select = OS.isMac ? event.metaKey : event.ctrlKey;
      const multi_select = event.shiftKey;
      const single_select = !toggle_select && !multi_select;
      return {
        toggle_select: toggle_select,
        multi_select: multi_select,
        single_select: single_select,
      };
    },
    select(event, source, index) {
      if (event.buttons != MouseButtons.primary) {
        return;
      }

      // console.log('select', source, source.source_id, 'selected:', source.selected, event);
      // console.log('select', source, source.source_id);
      console.log('select', source, source.source_id, 'buttons', event.buttons);
      const behavior = this.select_behavior(event);

      // Allow drag of selected items. If a drag wasn't performed then the click
      // is processed during mouse up.
      if (source.selected && behavior.single_select) {
        console.log('> deferring single-select of pre-selected item');
        return;
      }

      event.preventDefault(); // Prevent drag when doing drag-select.
      this.mousedown_index = index;
      // Clear existing selection unless Ctrl is pressed.
      if (!behavior.toggle_select) {
        // console.log('> clear-select');
        for (const item of this.sources) {
          item.selected = false;
        }
      }
      if (behavior.multi_select && this.last_selected_index !== null) {
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
    select_mouseup(event, source, index) {
      // Note this is querying `button` instead of `buttons` because it's the
      // only thing that indicate which button was released. `buttons` will
      // claim no button is pressed.
      if (event.button != MouseButton.primary) {
        // console.log('select_mouseup', 'not primary button', event.button)
        return;
      }

      // console.log('select_mouseup', source, source.source_id, 'selected:', source.selected, event);
      // console.log('select_mouseup', source, source.source_id);
      console.log('select_mouseup', source, source.source_id, 'button', event.button);
      // console.log(event);
      const behavior = this.select_behavior(event);
      // console.log('behavior', behavior);

      // In case the user clicked on a selected item, that might be part of a
      // large selection, the down-click was not processed because it might
      // result in a drag. This handling must then be processed on mouse up.
      if (behavior.single_select) {
        // Don't do anything if the selection doesn't change.
        // console.log('> selection size', this.selected.length)
        if (!(this.selected.length == 1 && this.selected[0].source_id != source.source_id)) {
          console.log('> deferred single-select');
          for (const item of this.sources) {
            item.selected = false;
          }
          source.selected = !source.selected;
          this.last_selected_index = index;
        }
      }
    },
    drag_select(event, source, index) {
      if (event.buttons != MouseButtons.primary) {
        return;
      }
      if (this.last_selected_index == index) {
        return;
      }
      // If starting a drag on a selected item, that should initiate drag and
      // drop, not drag-select.
      if (source.selected) {
        return;
      }
      console.log('drag_select');
      event.preventDefault(); // Prevent drag and drop while a drag-select is active.
      // console.log('drag_select', source, source.source_id, 'selected:', source.selected, event);
      const behavior = this.select_behavior(event);
      if (behavior.toggle_select) {
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
    // --- Drag & Drop Logic ---
    // https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API
    drag_start(event, source) {
      console.log('drag_start', source.source_id, source.path, event);
      // Add the target element's id to the data transfer object
      // event.dataTransfer.setData("text/plain", event.target.id);
      // event.dataTransfer.dropEffect = "copy";

      // event.dataTransfer.setData("application/my-app", event.target.id);
      event.dataTransfer.effectAllowed = "move";
    },
    drag_over(event, source) {
      // console.log('drag_over', event);
      // console.log('drag_over');
      event.preventDefault();
      event.dataTransfer.dropEffect = "move";

      this.drag_over_source_id = source.source_id
    },
    drag_drop(event, source) {
      console.log('drag_drop', source.source_id, source.path, event);
      event.preventDefault();
      // Get the id of the target and add the moved element to the target's DOM
      // const data = ev.dataTransfer.getData("text/plain");
      // ev.target.appendChild(document.getElementById(data));

      // Get the id of the target and add the moved element to the target's DOM
      // const data = event.dataTransfer.getData("application/my-app");
      // event.target.appendChild(document.getElementById(data));
      // console.log('> element', data);

      this.drag_over_source_id = null;

      const selected_ids = this.selected.map(source => source.source_id);
      sketchup.move_paths_to(selected_ids, source.source_id);
    },
    // --- Callbacks ---
    options() {
      sketchup.options();
    },
    undo() {
      sketchup.undo();
    },
    redo() {
      sketchup.redo();
    },
    scan_paths() {
      sketchup.scan_paths();
    },
    import_paths() {
      sketchup.import_paths();
    },
    export_paths() {
      sketchup.export_paths();
    },
    add_path() {
      sketchup.add_path();
    },
    edit_path(source_id) {
      sketchup.edit_path(source_id);
    },
    remove_path(source_id) {
      sketchup.remove_path(source_id);
    },
    reload_path(source_id) {
      sketchup.reload_path(source_id);
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
