module TT::Plugins::ExtensionSources

  # @note Debug method to reset and reload the extension.
  #
  # @example
  #   TT::Plugins::ExtensionSources.reset
  #
  # @return [Integer] Number of files reloaded.
  def self.reset
    reopen = self.app.close_extension_sources_dialog
    @app = nil
    result = self.reload
    self.app.boot
    self.app.open_extension_sources_dialog if reopen
    result
  end

  # @note Debug method to reload the extension.
  #
  # @example
  #   TT::Plugins::ExtensionSources.reload
  #
  # @return [Integer] Number of files reloaded.
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    load __FILE__ # rubocop:disable SketchupSuggestions/FileEncoding
    pattern = File.join(__dir__, '**/*.rb') # rubocop:disable SketchupSuggestions/FileEncoding
    Dir.glob(pattern).each { |file| load file }.size
  ensure
    $VERBOSE = original_verbose
  end

end # module
