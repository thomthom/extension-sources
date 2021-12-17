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
  },
  mounted: function () {
    sketchup.ready();
  },
});
