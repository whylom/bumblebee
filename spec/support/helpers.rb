module Helpers
  def stubbed_connection(&block)
    Faraday.new do |http|
      http.use Faraday::Adapter::Test, &block
    end
  end

  def receive_request(method, path=anything, params={}, headers={})
    receive(method).with(path, params, headers).and_call_original
  end

  def create_model(name = 'Model')
    Class.new(Bumblebee::Model) do
      define_singleton_method(:name) { name }
    end
  end
end
