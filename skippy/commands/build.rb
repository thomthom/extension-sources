require 'fileutils'
require 'pathname'
require 'zip'

require_relative '../../tools/lib/extension'

class Build < Skippy::Command

  include Thor::Actions

  desc 'release', 'Makes a release build of the extension.'
  def release

    ### Configure Paths ############################################################

    project_path = File.expand_path('../..', __dir__)
    project_pathname = Pathname.new(project_path)

    source_path = File.join(project_path, "src")
    source_pathname = Pathname.new(source_path)

    build_path = File.join(project_path, "build")
    build_pathname = Pathname.new(build_path)

    archive_path = File.join(project_path, "archive")
    FileUtils.mkdir_p(archive_path)


    ### Configure Files ############################################################

    extension = Extension.read_info(source_path)

    extension_name = extension[:name]
    say "Extension Name: #{extension_name}", [:yellow, :bold]

    extension_id = extension[:product_id]

    version = extension[:version]
    say "Version: #{version}", :green


    build_version = version
    build_date = Time.now.strftime("%Y-%m-%d")

    pattern = File.join(source_path, '*.rb')
    root_rb = Dir.glob(pattern).to_a.first
    basename = File.basename(root_rb, '.rb')

    archive_name = "#{basename}_#{build_version}_#{build_date}"
    archive = File.join(archive_path, "#{archive_name}.rbz")


    ### Create Build Directory #####################################################

    # say "Creating build directory..."

    # say "> Removing old build directory..."
    # say FileUtils.rm_rf(build_path).inspect

    # say "> Copy source to build directory..."
    # source = File.join(source_path, ".") # Copy the content - not the folder.
    # say FileUtils.cp_r(source, build_path).inspect

    # say "> Removing unwanted system cache files..."
    # unwanted_files = Dir.glob("#{build_path}/**/Thumbs.db")
    # say FileUtils.remove(unwanted_files).inspect

    # At the moment there's no need for a temporary build directory.
    build_path = source_path
    build_pathname = source_pathname


    ### Package ####################################################################

    say "Creating RBZ archive..."
    say "Source: #{build_path}"
    say "Destination: #{archive}"

    if File.exist?(archive)
      say "Archive already exist. Deleting existing archive."
      File.delete(archive)
    end

    build_files_pattern = File.join(build_path, "**", "**")
    Zip::File.open(archive, Zip::File::CREATE) do |zipfile|
      build_files = Dir.glob(build_files_pattern)
      build_files.each { |file_item|
        next if File.directory?(file_item)
        pathname = Pathname.new(file_item)
        relative_name = pathname.relative_path_from(build_pathname)
        say "Archiving: #{relative_name}"
        zipfile.add(relative_name, file_item)
      }
    end

    say "Packing done!", :green
    say "#{archive}", :blue

  end
  default_command :release

end
