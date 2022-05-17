module ExtensionSourcesFixtures

  # @return [String]
  def fixtures_path
    File.expand_path('../../../fixtures', __dir__)
  end

  # @param [String] fixture_name
  # @return [String]
  def fixture(fixture_name)
    File.join(fixtures_path, fixture_name)
  end

end # module
