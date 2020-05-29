require 'bumblebee/types'

module Bumblebee
  class Model
    include Bumblebee::Associations
    include Bumblebee::HTTP

    class << self
      delegate :where, :header, to: :all

      def uri(template = default_uri_template)
        @uri ||= URI.new(template)
      end

      def scope(name, proc)
        define_singleton_method(name, proc)
      end

      def all
        Relation.new(self)
      end

      def load(attributes)
        new(attributes).tap { |model| model.persisted = true }
      end

      def create(attributes)
        new(attributes).tap { |model| model.save }
      end

      def create!(attributes)
        new(attributes).tap { |model| model.save! }
      end

      def find(id)
        raise ArgumentError, "ID cannot be nil" unless id
        get(uri.with(id)).record
      end

      def find_by(conditions)
        where(conditions).first
      end

      def default_uri_template
        "#{resource}/:id"
      end

      def resource
        name.demodulize.underscore.pluralize
      end

      def attribute(name, type)
        typecasts[name] = type
      end

      def typecasts
        @typecasts ||= {}
      end
    end

    attr_accessor :persisted
    attr_reader :attributes, :exception, :errors

    alias persisted? persisted

    def initialize(attributes={})
      @attributes = attributes.with_indifferent_access
      @persisted = false
    end

    def reload
      @attributes = request(:get).data.with_indifferent_access
      self
    end

    def save
      save! && true
    rescue Bumblebee::RequestError => exception
      @exception = exception
      false
    end

    def save!
      handle_json_errors do
        result = (persisted? ? save_existing : save_new)
        self.attributes.merge!(result.data)
        self.persisted = true
      end
    end

    def update(attributes)
      self.attributes.merge!(attributes)
      save
    end

    def update!(attributes)
      self.attributes.merge!(attributes)
      save!
    end

    def destroy!
      handle_json_errors do
        persisted? ? destroy_existing : destroy_new
        self.persisted = false
      end
    end

    def destroy
      destroy!
      true
    rescue Bumblebee::RequestError => exception
      @exception = exception
      false
    end

    private

    def destroy_existing
      delete
      self.id = nil
    end

    def destroy_new
      # No-op
    end

    def save_new
      post(attributes)
    end

    def save_existing
      put(attributes)
    end

    def method_missing(name, *args, &block)
      case
      when association?(name) then association(name)
      when getter?(name)      then get_attribute(name)
      when setter?(name)      then set_attribute(name, args.first)
      else super
      end
    end

    def getter?(name)
      attributes.has_key?(name)
    end

    def setter?(name)
      name.to_s.ends_with? '='
    end

    def get_attribute(name)
      typecast(name: name, value: attributes[name])
    end

    def set_attribute(name, value)
      key = name.to_s.gsub(/=$/, '')
      attributes[key] = typecast(name: key, value: value)
    end

    def typecast(name:, value:)
      Bumblebee::Types.cast(value, self.class.typecasts[name])
    end
  end
end
