require 'bumblebee'
require 'faraday'

Dir[__dir__ + '/support/*'].each { |file| require file }

RSpec.configure do |c|
  c.include Helpers
end
