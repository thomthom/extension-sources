require 'tt_extension_sources/utils/inspection'

module TT::Plugins::ExtensionSources
  # Scans for the path to SketchUp extensions by looking for usage of
  # `Sketchup.register_extension` in .rb files.
  class ExtensionSourcesScanner

    include Inspection

    # @param [String] path
    # @return [Array<String>]
    def scan(path)
      paths = []
      pattern = File.join(path, '**/*.rb')
      # To ensure that parent directories are processed first before deeper
      # nested directories they are first sorted by path length.
      file_paths = Dir.glob(pattern).to_a.sort { |a, b|
        # Sort by size then by string value.
        comparison = a.size <=> a.size
        comparison == 0 ? a <=> b : comparison
      }
      file_paths.each { |file_path|
        dir_path = File.dirname(file_path)

        # Don't scan deeper in paths that already have found to be an
        # extension path.
        next if registered?(paths, dir_path)
        next if !register_extension?(file_path)

        paths << dir_path
      }
      paths
    end

    private

    # Ruby comment token.
    COMMENT_TOKEN = '#'.freeze

    # SketchUp method for registering extensions.
    REGISTER_EXTENSION = 'Sketchup.register_extension'.freeze

    # @param [Array<String>] known_paths
    # @param [String] path
    def registered?(known_paths, path)
      known_paths.any? { |scanned_path|
        path.start_with?(scanned_path)
      }
    end

    # @param [String] file_path
    def register_extension?(file_path)
      File.open(file_path, 'r:utf-8') do |file|
        file.each do |line|
          next if line.lstrip.start_with?(COMMENT_TOKEN)
          return true if line.include?(REGISTER_EXTENSION)
        end
      end
      false
    end

  end # class
end # module
