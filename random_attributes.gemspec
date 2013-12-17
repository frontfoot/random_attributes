# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'random_attributes/version'

Gem::Specification.new do |spec|
  spec.name          = "random_attributes"
  spec.version       = RandomAttributes::VERSION
  spec.authors       = ["Rufus Post"]
  spec.email         = ["rufuspost@gmail.com"]
  spec.description   = %q{When someone gives you rubbish data an you want to map it to something else.}
  spec.summary       = %q{Data hash to object mapper}
  spec.homepage      = "https://github.com/frontfoot/random_attributes"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "active_support", ">= 3.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "ffaker"
end
