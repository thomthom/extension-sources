let app = new Vue({
  el: '#app',
  data: {
    sources: [],
  },
  methods: {
    source_enabled_id(source_id) {
      return `sourceEnabled${source_id}`;
    },
    update(sources) {
      this.sources = sources;
    },
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
    }
  },
  mounted() {
    sketchup.ready();
  },
});
