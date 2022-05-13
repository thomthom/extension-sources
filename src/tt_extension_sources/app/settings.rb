module TT::Plugins::ExtensionSources
  # @abstract Interface for defining an application settings class.
  #
  # Use the class' DSL helpers to define the setting properties.
  #
  # @example
  #   class AppSettings < Settings
  #
  #     def initialize
  #       super('extension.company.com')
  #     end
  #
  #     define :debug, false
  #     define :tolerance, 0.001
  #
  #   end # class
  #
  #   settings = AppSettings.new
  #   # ...
  #   settings.debug = !settings.debug?
  #   settings.tolerance = 0.023
  class Settings

    # Define the setting property for this class. This will define getters and
    # setters for the given property.
    #
    # @note The getter for properties with a boolean default will automatically
    #   a `?` postfix.
    #
    # @param [Symbol] key
    # @param [Object] default
    #
    # @!macro [attach] app.setting
    #   **Default:** `$2`
    #   @!attribute [rw] $1
    def self.define(key, default = nil)
      read_method = boolean?(default) ? "#{key}?".to_sym : key.to_sym
      write_method = "#{key}=".to_sym
      self.class_eval {
        define_method(read_method) { |default_value = default|
          read(key.to_s, default_value)
        }
        define_method(write_method) { |value|
          write(key.to_s, value)
        }
      }
      nil
    end

    # @private
    # @param [Object] value
    def self.boolean?(value)
      value.is_a?(TrueClass) || value.is_a?(FalseClass)
    end

    # @param [String] preference_id
    def initialize(preference_id)
      @preference_id = preference_id
      # Reading and writing to the registry is slow. Cache values in order to
      # gain performance improvements.
      @cache = {}
    end

    # @return [String]
    def inspect
      to_s
    end

    private

    # @param [Symbol] key
    # @param [Object] default
    # @return [Object]
    def read(key, default = nil)
      if @cache.key?(key)
        @cache[key]
      else
        value = Sketchup.read_default(@preference_id, key, default)
        @cache[key] = value
        value
      end
    end

    # @param [Symbol] key
    # @param [Object] value
    # @return [Object]
    def write(key, value)
      @cache[key] = value
      escaped_value = escape_quotes(value)
      Sketchup.write_default(@preference_id, key, escaped_value)
      value
    end

    # @param [Object] value
    def escape_quotes(value)
      # TODO(thomthom): Include Hash? Likely value to store.
      if value.is_a?(String)
        value.gsub(/"/, '\\"')
      elsif value.is_a?(Array)
        value.map { |sub_value| escape_quotes(sub_value) }
      else
        value
      end
    end

  end

end # module TT::Plugins::SUbD
