let app = new Vue({
  el: '#app',
  data: {
    message: 'Extension Sources',
    sources: [],
  },
  methods: {
    update(sources) {
      this.sources = sources;
    },
    undo() {
      sketchup.undo();
    },
    redo() {
      sketchup.redo();
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
    edit_path(path_id) {
      sketchup.edit_path(path_id);
    },
    remove_path(path_id) {
      sketchup.remove_path(path_id);
    },
    reload_path(path_id) {
      sketchup.reload_path(path_id);
    }
  },
  mounted: function () {
    sketchup.ready();
  },
});
