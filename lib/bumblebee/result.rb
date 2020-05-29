module Bumblebee
  class Result
    attr_reader :model, :data, :page, :total, :total_pages

    def initialize(model, params)
      @model = model

      @data = params[:data]

      @page        = params[:page].to_i
      @total       = params[:total].to_i
      @total_pages = params[:total_pages].to_i
    end

    def records
      data.map { |attrs| model.load(attrs) }
    end

    def record
      raise "Cannot get single record from a collection result" if collection?
      model.load(data)
    end

    def collection?
      data.is_a? Array
    end
  end
end
