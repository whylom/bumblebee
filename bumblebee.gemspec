# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bumblebee/version'

Gem::Specification.new do |spec|
  spec.name          = "bumblebee"
  spec.version       = Bumblebee::VERSION
  spec.authors       = ["David Stamm", "David Workman", "Joe Simoes"]
  spec.email         = ["david@generalassemb.ly", "davew@generalassemb.ly", "joe@generalassemb.ly"]

  spec.summary       = %q{Build ActiveRecord-like models to interact with REST APIs}
  spec.homepage      = "https://github.com/generalassembly/bumblebee"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://gem.fury.io"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport', '>= 3.2', '< 7'
  spec.add_runtime_dependency 'faraday', '~> 0.9.2'
  spec.add_runtime_dependency 'uri_template', '~> 0.7.0'

  spec.add_development_dependency 'rspec', '~> 3.3.0'
  spec.add_development_dependency 'pry-byebug', '~> 3.2.0'
  spec.add_development_dependency 'webmock', '~> 1.22'
end
