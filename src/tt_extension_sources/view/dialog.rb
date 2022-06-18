module TT::Plugins::ExtensionSources
  # @abstract Base dialog interface with common dialog functionality.
  #
  # Methods that sub-classes must implement:
  # * {#create_dialog}
  # * {#init_action_callbacks}
  class Dialog

    # @param [Array<Symbol>] event_names
    def initialize(event_names)
      @events = setup_events(event_names)
      @dialog = create_dialog
    end

    # @param [Symbol] event
    def on(event, &block)
      raise "unknown event: #{event}" unless @events.key?(event)

      @events[event] << block
    end

    # @return [nil]
    def bring_to_front
      @dialog.bring_to_front
    end

    # @return [nil]
    def show
      visible? ? bring_to_front : init_and_show
      nil
    end

    # @return [Boolean]
    def close
      if @dialog.visible?
        @dialog.close
        return true
      end
      false
    end

    def visible?
      @dialog.visible?
    end

    # @return [Boolean] The resulting visibility state.
    def toggle
      visible? ? close : show
      visible?
    end

    private

    # @param [Array<Symbol>] event_names
    # @return [Hash]
    def setup_events(event_names)
      Hash[event_names.map { |key| [key, []] }]
    end

    # Ensures that the action callbacks are initialized before showing the
    # dialog.
    #
    # @return [nil]
    def init_and_show
      raise "don't initialize if dialog is shown" if @dialog.visible?

      init_action_callbacks(@dialog)
      @dialog.show
      nil
    end

    # @param [String] function
    # @param [Array<#to_json>] args
    # @return [nil]
    def call_js(function, *args)
      params = args.map(&:to_json).join(',')
      @dialog.execute_script("#{function}(#{params})")
      nil
    end

    # @param [Symbol] event
    # @return [nil]
    def trigger(event, *args)
      raise "unknown event: #{event}" unless @events.key?(event)
      warn "event without listeners: #{event}" if @events[event].empty?

      @events[event].each { |callback| callback.call(*args) }
      nil
    end

    # @return [UI::HtmlDialog]
    def create_dialog
      raise NotImplementedError
    end

    # @param [UI::HtmlDialog] dialog
    def init_action_callbacks(dialog)
      raise NotImplementedError
    end

    # Objects passed from JavaScript will have their keys represented as
    # strings. This utility converts the keys to Symbols.
    #
    # @param [Hash{String => Object}, Enumerable, Object] object
    # @return [Hash{Symbol => Object}, Enumerable, Object]
    def symbolize_keys(object)
      if object.is_a?(Hash)
        Hash[object.map { |k, v| [k.to_sym, symbolize_keys(v)] }]
      elsif object.is_a?(Enumerable)
        return object.map { |item| symbolize_keys(item) }
      else
        object
      end
    end

    # @return [String]
    def ui_path
      path = __dir__
      path.force_encoding('utf-8')
      File.join(path, 'ui')
    end

  end

end #module
