require 'minitest/mock'
require "minitest/reporters"
require 'set'

# Kludge: minitest-reporter depend on the `ansi` gem which hasn't been updated
# for a very long time. It's expecting to use another `win32console` gem in
# order to provide colorized output on Windows even though that is not longer
# needed. This works around that by fooling Ruby to think it has been loaded.
#
# https://github.com/rubyworks/ansi/issues/36
# https://github.com/rubyworks/ansi/pull/35
$LOADED_FEATURES << 'Win32/Console/ANSI'
Minitest::Reporters.use!

# In case there is no diff tool, try to find the diff tool from the default
# installation directory.
if Minitest::Assertions.diff.nil?
  win_diff = "#{ENV['ProgramFiles']}/Git/usr/bin/diff.exe"
  if system(win_diff, __FILE__, __FILE__)
    Minitest::Assertions.diff = %["#{win_diff}" -u]
  end
end

# Make it easier to verify the absence of a call to a mock.
class Minitest::Mock

  # @param [Symbol] name
  def refuse(name)
    @refused_calls ||= Set.new
    @refused_calls << name
    expect(name, nil) do
      raise MockExpectationError, "unexpected call to #{name}"
    end
    self
  end

  alias __verify_internal verify
  private :__verify_internal

  def verify
    @refused_calls ||= Set.new
    @refused_calls.each { |name|
      @expected_calls.delete(name)
    }
    __verify_internal
  end

end


# Because this project targets SketchUp 2017 it has to remain compatible with
# Ruby 2.2. This means <<~ heredocs won't work. As a workaround this utility
# can be used instead:
#
# string = <<~EOT
#   Indented string.
#     Of multiline.
# EOT
#
# Becomes:
#
# string = <<-EOT.undent_heredoc
#   Indented string.
#     Of multiline.
# EOT
#
# https://stackoverflow.com/a/16150611/486990
class String
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      __send__(*a, &b)
    end
  end

  def undent_heredoc
    indent = scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
    gsub(/^[ \t]{#{indent}}/, '')
  end
end


# Define the nested extension namespace.
module TT
  module Plugins
    module ExtensionSources
    end
  end
end
