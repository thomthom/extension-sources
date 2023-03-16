require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/model/statistics'
require 'tt_extension_sources/model/version'
require 'tt_extension_sources/utils/inspection'
require 'tt_extension_sources/utils/timing'

module TT::Plugins::ExtensionSources
  class ExtensionLoader

    include Inspection

    attr_reader :loaded_extensions

    # @param [SystemInterface] system
    # @param [Statistics] statistics
    def initialize(system:, statistics: nil)
      @system = system
      @statistics = statistics
      @timing = Timing.new
      @loaded_extensions = []
      @errors_detected = false
    end

    # @param [ExtensionSource] source
    # @return [Array<String>]
    def require_source(source)
      pattern = "#{source.path}/*.rb"
      files = Dir.glob(pattern).each { |path|
        # Check if an extension is already loaded for the given path.
        extension = find_extension(path)

        require_result = nil
        @timing.measure do
          require_result = @system.require(path)
        end
        @errors_detected = true unless require_result

        # Only keep track of new extensions registered.
        if extension.nil?
          extension = find_extension(path)
          @loaded_extensions << extension if extension
        end
      }.to_a

      if valid_measurement?
        source.load_time = @timing.lapsed
        log_require_time(source)
      end

      files
    end

    # The timing measurements only makes sense to log if the extension loaded
    # successfully. This is not possible to detect 100% accurately because
    # `Sketchup.require` returns `false` for both load errors and if the file
    # has already been loaded. Because of this the measurements are only logged
    # if it's detected that an extension matching the filepath required is
    # marked as loaded.
    def valid_measurement?
      !errors_detected? &&
          loaded_extensions.size == 1 &&
          loaded_extensions[0] &&
          loaded_extensions[0].loaded?
    end

    def errors_detected?
      @errors_detected
    end

    private

    # @param [String] path
    # @return [SketchupExtension]
    def find_extension(path)
      @system.extensions.find { |extension|
        extension.extension_path == path
      }
    end

    # @param [ExtensionSource] source
    def log_require_time(source)
      return if @statistics.nil?

      sketchup_version = @system.metadata[:sketchup_version] || Version.new
      row = Statistics::Record.new(
        sketchup: sketchup_version.to_s,
        path: source.path,
        load_time: source.load_time,
        timestamp: Time.now
      )
      @statistics.record(row)
      nil
    end

  end # class
end # module
