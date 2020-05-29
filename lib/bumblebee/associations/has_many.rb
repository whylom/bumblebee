module Bumblebee
  module Associations
    class HasMany < Bumblebee::Associations::Base
      def for(parent)
        if array = parent.attributes[child_name]
          Result.new(child_class, data: array).records
        else
          Relation.new(child_class, uri: uri.with(parent))
        end
      end

      def uri
        if options[:uri]
          URI.new(options[:uri])
        else
          parent_class.uri.append(child_name)
        end
      end
    end
  end
end
