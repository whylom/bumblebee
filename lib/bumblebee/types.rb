require 'date'
require 'json'

module Bumblebee
  module Types
    def self.register_type(type, cast_proc)
      raise ArgumentError, "cast_proc needs to be Callable" unless cast_proc.respond_to?(:call)
      registered_types[type] = cast_proc
    end

    def self.registered_types
      @registered_types ||= {}
    end

    def self.cast(value, type)
      return value if type.nil? || value.nil? || value.is_a?(type)
      raise ArgumentError, "Unknown type #{type.name}" unless registered_types.has_key?(type)
      registered_types[type].call(value)
    end

    # Standard typecasts
    register_type Integer, ->(value) { value.to_i }
    register_type String, ->(value) { value.to_s }
    register_type Float, ->(value) { value.to_f }
    register_type JSON, ->(value) { JSON.parse(value) }
    register_type Date, ->(value) { Date.iso8601(value) }
    register_type Time, ->(value) { Time.iso8601(value) }
    register_type DateTime, ->(value) { DateTime.iso8601(value) }
  end
end
