module TestExample

  TEST_SKETCHUP.require 'dummy_valid_extension/other'
  TEST_SKETCHUP.require 'dummy_valid_extension/another'

  def self.hello
    'world'
  end

end # module
