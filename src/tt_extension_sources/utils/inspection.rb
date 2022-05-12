module TT::Plugins::ExtensionSources
  # Include to provide utility methods for inspecting objects.
  module Inspection

    # @param [Class] klass
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    # Class methods added when including {Inspection}.
    module ClassMethods

      # @return [String] The class name with the extension namespace stripped.
      def object_name
        @object_name ||= name.split('::').slice(3..-1).join('::')
        @object_name
      end

    end # class ClassMethods

  end # class
end # module
