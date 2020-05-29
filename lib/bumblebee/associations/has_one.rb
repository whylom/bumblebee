module Bumblebee
  module Associations
    class HasOne < Bumblebee::Associations::Base
      def for(parent)
        if hash = parent.attributes[child_name]
          Result.new(child_class, data: hash).record
        else
          child_class.get( uri.with(parent) ).record
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
