module Bumblebee
  module Associations
    def self.included(base)
      base.class_attribute :associations
      base.associations = {}

      base.extend ClassMethods
    end

    module ClassMethods
      def belongs_to(name, options={})
        self.associations[name] = Associations::BelongsTo.new(self, name, options)
      end

      def has_one(name, options={})
        self.associations[name] = Associations::HasOne.new(self, name, options)
      end

      def has_many(name, options={})
        self.associations[name] = Associations::HasMany.new(self, name, options)
      end
    end

    def association?(name)
      self.associations.include?(name)
    end

    def association(name)
      self.associations[name].for(self)
    end
  end
end
