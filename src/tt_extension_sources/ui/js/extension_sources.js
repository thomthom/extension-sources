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
    add_path() {
      sketchup.add_path();
    },
    remove_path(path) {
      sketchup.remove_path(path);
    },
    reload_path(path) {
      sketchup.reload_path(path);
    }
  },
  mounted: function () {
    sketchup.ready();
  },
});
