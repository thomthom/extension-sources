require 'tt_extension_sources/utils/inspection'

module TT::Plugins::ExtensionSources
  # Scans for the path to SketchUp extensions by looking for usage of
  # `Sketchup.register_extension` in .rb files.
  class ExtensionSourcesScanner

    include Inspection

    # @param [String] path
    # @param [Array<String>] exclude Paths to exclude from results.
    # @return [Array<String>]
    def scan(path, exclude: [])
      paths = []
      pattern = File.join(path, '**/*.rb')
      # To ensure that parent directories are processed first before deeper
      # nested directories they are first sorted by path length.
      file_paths = Dir.glob(pattern).to_a.sort { |a, b|
        # Sort by size then by string value.
        comparison = a.size <=> a.size
        comparison == 0 ? a <=> b : comparison
      }
      # To ensure `skip_path?` doesn't match on partial path components a
      # path separator is appended to the end of the paths.
      processed_paths = exclude.map { |item| path_with_end_separator(item) }
      file_paths.each { |file_path|
        dir_path = File.dirname(file_path)
        dir_with_separator = path_with_end_separator(dir_path)

        # Don't scan deeper in paths that are found to be an extension path or
        # otherwise excluded from appearing in the results.
        next if skip_path?(processed_paths, dir_with_separator)
        next if !has_register_extension?(file_path)

        processed_paths << dir_with_separator
        paths << dir_path
      }
      paths
    end

    private

    # Ruby comment token.
    COMMENT_TOKEN = '#'.freeze

    # SketchUp method for registering extensions.
    REGISTER_EXTENSION = 'Sketchup.register_extension'.freeze

    def path_with_end_separator(path)
      "#{path}#{File::SEPARATOR}"
    end

    # @param [Array<String>] known_paths
    # @param [String] path
    def skip_path?(known_paths, path)
      known_paths.any? { |scanned_path|
        path.start_with?(scanned_path)
      }
    end

    # @param [String] file_path
    def has_register_extension?(file_path)
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
