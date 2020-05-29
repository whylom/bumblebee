module Bumblebee
  class Relation
    attr_accessor :model, :headers, :params, :uri

    delegate :to_a, to: :each

    def initialize(model, headers: {}, params: {}, uri: model.uri)
      @model = model
      @headers = headers
      @params = params
      @uri = uri
    end

    def where(params)
      clone.tap { |c| c.params.merge!(params) }
    end

    def header(headers)
      clone.tap { |c| c.headers.merge!(headers) }
    end

    def first
      pages.first.first
    end

    def last
      pages.last.last
    end

    def pages
      Pager.new(self)
    end

    def count
      get.total
    end

    def each(&block)
      return enum_for(:each) unless block_given?
      pages.each { |records| records.each(&block) }
    end

    def get
      request :get
    end

    def request(method)
      model.request(method, uri, params, headers)
    end

    def merge(scope)
      where(scope.params).header(scope.headers)
    end

    def use_model_scope(name, *args)
      merge model.send(name, *args)
    end

    def clone
      Relation.new(model, headers: headers.clone,
                          params: params.clone,
                          uri: uri.clone)
    end

    def method_missing(name, *args, &block)
      # handle chained scopes (eg: Model.one.two) by delegating any requests
      # for a scope back to the model class and merging the results
      if model.respond_to? name
        use_model_scope(name, *args)
      else
        super
      end
    end
  end
end
