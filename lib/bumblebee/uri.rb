require 'uri_template'

module Bumblebee
  class URI
    attr_accessor :template, :params

    def initialize(template, params = {})
      @template, @params = template, params
    end

    def append(path)
      clone.tap { |uri| uri.template = join(template, path) }
    end

    def with(arg)
      clone.tap do |uri|
        case arg
        when Hash            then uri.params.merge!(arg)
        when Model           then uri.params.merge!(arg.attributes)
        when Integer, String then uri.params.merge!(id: arg)
        end
      end
    end

    def to_s
      fix_slashes( URITemplate.new(:colon, template).expand(params) )
    end

    def clone
      self.class.new(template.clone, params.clone)
    end

    def ==(other)
      to_s == other.to_s
    end

    private

    def join(*args)
      args.map(&:to_s).join('/')
    end

    def fix_slashes(string)
      string.gsub(%r{/+}, '/').chomp('/')
    end
  end
end
