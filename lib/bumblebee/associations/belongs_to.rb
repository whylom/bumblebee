module Bumblebee
  module Associations
    class BelongsTo < Bumblebee::Associations::Base
      def for(parent)
        if hash = parent.attributes[child_name]
          Result.new(child_class, data: hash).record
        else
          id = parent.attributes["#{child_name}_id"]
          child_class.find(id)
        end
      end
    end
  end
end
