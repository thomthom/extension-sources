# The SketchUp API namespace.
module Sketchup

  # This monkey-patches the Sketchup.require method such that older SketchUp
  # versions can be used in development while using Ruby 3's own new RBS file
  # format for type definitions.

  # @private
  # Search order of file extensions SketchUp will handle.
  ES_RB_FILE_EXTENSION_ORDER = ['rbe', 'rbs']
  private_constant :ES_RB_FILE_EXTENSION_ORDER

  # @private
  # The file extension for RBS files.
  ES_RBS_FILE_EXTENSION = 'rbs'
  private_constant :ES_RBS_FILE_EXTENSION

  # @private
  # The magic set of bytes for SketchUp's RBS files.
  ES_RBS_HEADER_SIGNATURE = 'RBS1.0'.encode(Encoding::BINARY)
  private_constant :ES_RBS_HEADER_SIGNATURE

  class << self

    unless method_defined?(:es_require_original)

      # @private
      # The original `require` method that's being patched.
      alias :es_require_original :require

      # @param [String] filename
      def require(filename)
        # Resolve implicit file extensions for RBE and RBS files, which takes
        # priority in filename resolution.
        if File.extname(filename).empty?
          ES_RB_FILE_EXTENSION_ORDER.each { |ext|
            path = "#{filename}.#{ext}"
            filename = path if File.exist?(path)
          }
        end

        # Sniff out the header of the RBS files.
        if File.exist?(filename) && File.extname(filename).downcase == ES_RBS_FILE_EXTENSION
          File.open(filename) { |file|
            header = file.read(ES_RBS_HEADER_SIGNATURE.size)
            return false if header != ES_RBS_HEADER_SIGNATURE
          }
        end

        # Fall back to the original require.
        es_require_original(filename)
      end

    end

  end

end if Sketchup.version.to_f < 22.1
