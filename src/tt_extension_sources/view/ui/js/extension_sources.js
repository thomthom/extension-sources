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

console.log('sketchup', typeof sketchup);
if (typeof sketchup === 'undefined') {
  console.log('Browser testing shims');
  window.sketchup = {
    move_paths_to() { },
    options() { },
    undo() { },
    redo() { },
    scan_paths() { },
    import_paths() { },
    export_paths() { },
    add_path() { },
    edit_path() { },
    remove_path() { },
    reload_path() { },
    source_changed() { },
    ready() {
      console.log('shim: ready()')
      items = [
        { source_id: 1, path: '/fake/path1', enabled: true, path_exist: true },
        { source_id: 2, path: '/fake/path2', enabled: true, path_exist: true },
        { source_id: 3, path: '/fake/path3', enabled: true, path_exist: true },
        { source_id: 4, path: '/fake/path4', enabled: true, path_exist: true },
        { source_id: 5, path: '/fake/path5', enabled: true, path_exist: true },
      ];
      setTimeout(() => app.update(items));
    },
  };
}

let app = new Vue({
  el: '#app',
  data: {
    filter: "",
    sources: [],
    // List UI state:
    last_selected_index: null,
    drag_over_source_id: null,
    drag_before: false,
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
        ui_state[item.source_id] = {
          selected: item.selected,
          draggable: item.draggable,
        };
      }
      for (const item of sources) {
        item.selected = ui_state[item.source_id]?.selected || false;
        item.draggable = ui_state[item.source_id]?.draggable || false;
        // item.selected = (item.source_id in ui_state) ? ui_state[item.source_id].selected : false;
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
        console.log('select', 'not primary buttons', event.buttons)
        return;
      }

      // console.log('select', source, source.source_id, 'selected:', source.selected, event);
      // console.log('select', source, source.source_id);
      console.log('select', source, source.source_id, 'buttons', event.buttons);
      const behavior = this.select_behavior(event);

      let is_drag_handle = event.target.closest('.es-drag-handle') !== null;
      // console.log('is_drag_handle', is_drag_handle, service.selected);
      // Don't change the selection when clicking the drag handle of a selected
      // item. But allow selection to change when clicking the drag handle of
      // and unselected item. (Doesn't make sense to drag an unselected item.)
      console.log('> is_drag_handle:', is_drag_handle, 'selected:', source.selected);
      if (is_drag_handle && source.selected) {
        console.log('> bail');
        return;
      }

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
    // --- Drag & Drop Logic ---
    // https://developer.mozilla.org/en-US/docs/Web/API/HTML_Drag_and_Drop_API
    drag_start(event, source) {
      console.log('drag_start', source.source_id, source.path, event);
      event.dataTransfer.effectAllowed = "move";
    },
    drag_end(event, source) {
      console.log('drag_end', source.source_id, source.path, event);
      this.drag_over_source_id = null;
      source.draggable = false; // Because .es-drag-handle onmouseup doesn't trigger after a drag.

      // Workaround for SketchUp bug:
      // On Windows the `drop` event fails to trigger on the very first drop.
      // (Tested on SketchUp up til SU2022.0).
      // To work around this the `dragend` event is used instead. This event
      // is called on the element that started `dragstart`, so the target
      // target element must be computed manually.

      // Check if the drop was cancelled.
      if (event.dataTransfer.dropEffect == "none") {
        return;
      }

      // Find the target list item and the associated source item.
      let target = this.drag_target_from_point(event.x, event.y);
      let source_id = parseInt(target.dataset.sourceId);
      console.log('source id:', source_id, typeof source_id);

      // let target_source = this.sources.find(item => item.source_id == source_id);
      // console.log(target_source);

      // This is what the `drop` event would do, if it worked reliably:
      this.drag_selected_to_target(source_id);
    },
    drag_enter(event, source) {
      console.log('drag_enter');
      event.preventDefault();
      event.dataTransfer.dropEffect = "move";

      this.drag_over_source_id = source.source_id
      this.drag_before = this.is_drop_target_before(event.target, event.x, event.y);
    },
    drag_over(event, source) {
      console.log('drag_over');
      event.preventDefault();
      event.dataTransfer.dropEffect = "move";

      this.drag_over_source_id = source.source_id
      this.drag_before = this.is_drop_target_before(event.target, event.x, event.y);
    },
    drag_drop(event, source) {
      console.log('drag_drop', source.source_id, source.path, event);
      event.preventDefault();

      // Bug: This doesn't work properly in SketchUp on Windows. See `drag_end`.
      // this.drag_selected_to_target(source_id);
    },
    is_drop_target_before(target, x, y) {
      // console.log('drag_before_or_after', x, y);

      target = target.closest('.su-source');
      // console.log(target, x, y);

      let bounds = target.getBoundingClientRect();
      let relative_y = y - bounds.y;
      let before = relative_y < (bounds.height / 2);
      // console.log(bounds, relative_y, bounds.height, before);
      return before;
    },
    drag_target_from_point(x, y) {
      let target = document.elementFromPoint(x, y);
      console.log('elementFromPoint', target);

      let list_item = target.closest('.su-source');
      console.log('closest', list_item);

      return list_item
    },
    drag_selected_to_target(source_id) {
      const selected_ids = this.selected.map(item => item.source_id);
      if (selected_ids.length == 1 && source_id == selected_ids[0]) {
        return; // Nothing was moved.
      }
      console.log('reorder', selected_ids, source_id, this.drag_before);
      sketchup.reorder(selected_ids, source_id, this.drag_before);
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
    // setTimeout(() => sketchup.ready());
  },
});
