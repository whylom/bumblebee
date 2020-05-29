module Bumblebee
  module Associations
    class Base
      attr_reader :parent_class, :child_name, :options

      def initialize(parent_class, child_name, options = {})
        @parent_class = parent_class
        @child_name = child_name
        @options = options
      end

      def child_class
        @child_class ||= resolve_child_class
      end

      private

      def resolve_child_class
        classname = child_name.to_s.classify

        lookup_path(parent_class.name).each do |namespace|
          klass = "#{namespace}::#{classname}".safe_constantize
          return klass if klass
        end

        raise NameError, "uninitialized constant #{classname}"
      end

      def lookup_path(name)
        if name.blank?
          []
        else
          [name.deconstantize] + lookup_path(name.deconstantize)
        end
      end
    end
  end
end
