require 'json'

require 'extensions'
require 'sketchup'

module Example

  file = __FILE__.dup
  # Account for Ruby encoding bug under Windows.
  file.force_encoding('UTF-8') if file.respond_to?(:force_encoding)
  # Support folder should be named the same as the root .rb file.
  folder_name = File.basename(file, '.*')

  # Path to the root .rb file (this file).
  PATH_ROOT = File.dirname(file).freeze

  # Path to the support folder.
  PATH = File.join(PATH_ROOT, folder_name).freeze

  extension_json_file = File.join(PATH, 'extension.json')
  extension_json = File.read(extension_json_file)
  # Extension meta-data.
  EXTENSION = ::JSON.parse(extension_json, symbolize_names: true).freeze

  unless file_loaded?(__FILE__)
    loader = File.join(PATH, 'app', 'main')
    @extension = SketchupExtension.new(EXTENSION[:name], loader)
    @extension.description = EXTENSION[:description]
    @extension.version     = EXTENSION[:version]
    @extension.copyright   = EXTENSION[:copyright]
    @extension.creator     = EXTENSION[:creator]
    # Sketchup.register_extension(@extension, true)
  end

end # module

file_loaded(__FILE__)
