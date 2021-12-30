module TT::Plugins::ExtensionSources
  module OS

    class << self

    # @return [String]
    def app_data_path
      @app_data ||= app_data_path_impl
      @app_data.dup
    end

    private

    # @return [String]
    def app_data_path_impl
      app_data = nil
      if Sketchup.platform == :platform_win
        path = ENV['APPDATA'].to_s.dup
        path.force_encoding('UTF-8')
        app_data = File.expand_path(path)
        unless File.exist?(app_data)
          # ENV variables might not yield a valid path when it contains unicode characters.
          # This is a quick and dirty hack - assumption on how to resolve the Roaming AppData path.
          app_data = File.expand_path('../../Roaming', Sketchup.temp_dir)
        end
      else
        home = File.expand_path(ENV['HOME'].to_s)
        app_data = File.join(home, 'Library', 'Application Support')
      end
      warn "app data not found: #{app_data}" unless File.exist?(app_data)
      app_data
    end

    end # class << self

  end # module
end # module
