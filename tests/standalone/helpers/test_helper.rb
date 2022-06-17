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


# Define the nested extension namespace.
module TT
  module Plugins
    module ExtensionSources
    end
  end
end
