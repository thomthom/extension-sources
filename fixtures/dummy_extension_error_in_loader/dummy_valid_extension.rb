module TestExample

  loader = File.join(__dir__, File.basename(__FILE__, '.*'), 'main')
  extension = TestExtension.new('Valid Extension', loader)
  TEST_SKETCHUP.register_extension(extension, true)

end # module