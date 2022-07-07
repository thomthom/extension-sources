require 'json'

class Version < Skippy::Command

  desc 'show', 'Show version information for the project.'
  def show
    project = Skippy::Project::current_or_fail
    say project.name, :bold
    say project.description

    # SketchUp Extension
    # TODO: Resolve src and extension filename from project.
    extension_json = project.path.join('src/tt_extension_sources/extension.json')
    extension = JSON.parse(extension_json.read, symbolize_names: true)
    say
    say 'Extension', [:yellow, :bold]
    say "  Version: #{extension[:version]}", :green
    say "  Build: #{extension[:build]}", :green
  end
  default_command :show

  class Bump < Skippy::Command

    desc 'build', 'Increase build version.'
    def build
      edit_info { |extension|
        # TODO: Convert build number to be an integer.
        old_build = extension[:build].to_i
        new_build = old_build + 1
        extension[:build] = new_build.to_s
      }
    end

    desc 'patch', 'Increase patch version.'
    def patch
      bump_version(PATCH)
    end

    desc 'minor', 'Increase minor version.'
    def minor
      bump_version(MINOR)
    end

    desc 'major', 'Increase major version.'
    def major
      bump_version(MAJOR)
    end

    private

    def edit_info(&block)
      extension_json = read_json(extension_json_path)
      old_version = version_number(extension_json)
      block.call(extension_json)
      new_version = version_number(extension_json)
      write_json(extension_json_path, extension_json)
      say "Bumped version: #{old_version} => #{new_version}", :yellow
      extension_json
    end

    def version_number(extension)
      "#{extension[:version]} (Build: #{extension[:build]})"
    end

    MAJOR = 0
    MINOR = 1
    PATCH = 2

    def bump_version(index)
      edit_info { |extension|
        version = extension[:version]
        parts = version.split('.').map(&:to_i)

        # Bump the version.
        parts[index] += 1
        # Reset the lower numbers to zero.
        (index + 1...parts.size).each { |i| parts[i] = 0 }
        # Reset build version.
        extension[:build] = 1

        version = parts.join('.')
        extension[:version] = version
      }
    end

    def read_json(pathname)
      JSON.parse(pathname.read(encoding: 'UTF-8'), symbolize_names: true)
    end

    def write_json(pathname, hash)
      pathname.write(JSON.pretty_generate(hash), encoding: 'UTF-8')
    end

    def extension_json_path
      project = Skippy::Project::current_or_fail
      # TODO: Resolve src and extension filename from project.
      project.path.join('src/tt_extension_sources/extension.json')
    end

  end # Build

end
