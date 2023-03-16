require 'tt_extension_sources/model/extension_source'
require 'tt_extension_sources/model/statistics'
require 'tt_extension_sources/model/version'
require 'tt_extension_sources/utils/inspection'
require 'tt_extension_sources/utils/timing'

module TT::Plugins::ExtensionSources
  class ExtensionLoader

    include Inspection

    attr_reader :loaded_extensions

    module RequireHook

      class RequireResult
        attr_accessor :success, :error
        def initialize(success:, error:)
          @success = success
          @error = error
        end
      end # class

      # @example
      #   ExtensionLoader::RequireHook.install_to(Sketchup)
      #
      # @param [Module, Object] obj
      def self.install_to(obj)
        unless obj.is_a?(ExtensionLoader::RequireHook)
          obj.singleton_class.prepend(ExtensionLoader::RequireHook)
        end
      end

      # alias :es_require_original :require

      # @param [String] path
      # @return [Boolean]
      def require(path)
        loaded_features = $LOADED_FEATURES.dup
        # success = es_require_original(path)
        success = super(path)
        unless success
          es_hook_record_require_errors(path, loaded_features)
        end
        success
      end

      # @private
      #
      # @example
      #   result = Sketchup.es_hook_require_with_errors(path)
      #   if result.error
      #     # ...
      #   end
      #
      # @param [String] path
      def es_hook_require_with_errors(path)
        es_hook_detect_require_errors = true
        require_result = self.require(path)
        result = RequireResult.new(
          success: require_result,
          error: !es_hook_require_errors.empty?
        )
        es_hook_detect_require_errors = false
        result
      end

      ES_REQUIRE_EXT = ['.rbe', '.rbs', '.rb', '.so', '.bundle'].freeze

      # @private
      # @return [Boolean]
      def es_hook_detect_require_errors?
        !!@es_detect_require_errors
      end

      # @private
      # @param [Boolean] value
      def es_hook_detect_require_errors=(value)
        @es_detect_require_errors = value
        es_hook_require_errors.clear
      end

      # @private
      # @return [Boolean]
      def es_hook_require_errors
        @es_require_errors ||= []
      end

      # @private
      # @param [String] path
      # @param [Array<String>] loaded_features
      def es_hook_record_require_errors(path, loaded_features)
        # TODO: Disable timing for this logic.
        return unless es_hook_detect_require_errors?

        # If the file was already loaded, then there was no error.
        expanded_path = es_expand_required_path(path, loaded_features)
        return if expanded_path && File.exist?(expanded_path)

        # Assume an error was the cause of the file failing to load.
        es_hook_require_errors << path
      end

      # @private
      # @param [String] path
      # @param [Array<String>] loaded_features
      # @return [String, nil]
      def es_hook_expand_required_path(path, loaded_features)
        # If the path was already in loaded features it's not an error.
        # Check with increasing costly search.

        # Check absolute path.
        return path if loaded_features.include?(path)

        # Check absolute path with expanded file extension.
        ES_REQUIRE_EXT.each { |ext|
          expanded_path = "#{path}.#{ext}"
          return expanded_path if loaded_features.include?(expanded_path)
        }

        # Check paths relative to $LOAD_PATH.
        $LOAD_PATH.each { |load_path|
          expanded_path = File.join(load_path, path)
          return expanded_path if loaded_features.include?(expanded_path)

          ES_REQUIRE_EXT.each { |ext|
            expanded_path = File.join(load_path, "#{path}.#{ext}")
            return expanded_path if loaded_features.include?(expanded_path)
          }
        }

        nil
      end

    end # class

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
