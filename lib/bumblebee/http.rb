module Bumblebee
  module HTTP
    METHODS = %i(get post put patch delete head options)

    def self.included(base)
      base.class_attribute :connection
      base.extend ClassMethods
    end

    module ClassMethods
      METHODS.each do |method|
        define_method(method) do |uri, params={}|
          request(method, uri, params)
        end
      end

      def request(method, uri, params={}, headers={})
        response = send_request(method, uri, params, headers)

        raise RequestError, response unless response_successful?(response)

        params = parse(response)
        Result.new(self, params)
      end

      def send_request(method, uri, params={}, headers={})
        connection.send(method, uri.to_s, params, headers)
      end

      def response_successful?(response)
        response.success?
      end

      def parse(response)
        { data: parse_data(response) }.merge(parse_pagination(response))
      end

      def parse_data(response)
        if response.status == 204
          {}
        else
          JSON.parse(response.body, symbolize_names: true)
        end
      end

      def parse_pagination(response)
        {
          page:        response.headers['X-Page'],
          total:       response.headers['X-Total'],
          total_pages: response.headers['X-Total-Pages']
        }
      end
    end

    METHODS.each do |method|
      define_method(method) do |params={}|
        request(method, params)
      end
    end

    def uri
      self.class.uri.with(self)
    end

    def request(method, params = {})
      self.class.request(method, uri, params)
    end

    def parse_errors(response)
      JSON.parse(response.body, symbolize_names: true).fetch(:errors, nil)
    rescue JSON::ParserError
      nil
    end

    def handle_json_errors
      @errors = nil
      yield
    rescue Bumblebee::RequestError => exception
      @errors = parse_errors(exception.response)
      raise
    end
  end
end
