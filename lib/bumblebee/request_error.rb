module Bumblebee
  class RequestError < StandardError
    attr_reader :response

    delegate :status, to: :response

    def initialize(response)
      @response = response
    end

    def message
      "Received #{response.status} response"
    end
  end
end
