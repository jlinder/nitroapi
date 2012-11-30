# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nitro_api/version'

Gem::Specification.new do |gem|
  gem.name          = "nitroapi"
  gem.version       = NitroApi::VERSION
  gem.authors       = ["Gilad Buchman", "James H. Linder"]
  gem.email         = ["gems@jlinder.com"]
  gem.description   = %q{Api client for Bunchball's Nitro. http://www.bunchball.com/nitro/}
  gem.summary       = %q{Api client for Bunchball's Nitro}
  gem.homepage      = %q{http://github.com/jlinder/nitroapi}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # Please keep me alphabetized!
  gem.add_dependency('activesupport')
  gem.add_dependency('json')

  gem.add_development_dependency('bundler', ['~> 1.2.2'])
  gem.add_development_dependency('rspec', ['~> 2.3.0'])
  gem.add_development_dependency('simplecov', ['~> 0.7.1'])
end

