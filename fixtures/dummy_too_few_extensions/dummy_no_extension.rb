module TestExample

  loader = File.join(__dir__, File.basename(__FILE__, '.*'), 'main')
  TEST_SKETCHUP.require(loader)

end # module
