require 'minitest/mock'
require 'set'

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
