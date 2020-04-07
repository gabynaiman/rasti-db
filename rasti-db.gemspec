# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rasti/db/version'

Gem::Specification.new do |spec|
  spec.name          = 'rasti-db'
  spec.version       = Rasti::DB::VERSION
  spec.authors       = ['Gabriel Naiman']
  spec.email         = ['gabynaiman@gmail.com']
  spec.summary       = 'Database collections and relations'
  spec.description   = 'Database collections and relations'
  spec.homepage      = 'https://github.com/gabynaiman/rasti-db'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sequel', '~> 5.0'
  spec.add_runtime_dependency 'treetop', '~> 1.4.8'
  spec.add_runtime_dependency 'consty', '~> 1.0', '>= 1.0.3'
  spec.add_runtime_dependency 'timing', '~> 0.1', '>= 0.1.3'
  spec.add_runtime_dependency 'class_config', '~> 0.0', '>= 0.0.2'
  spec.add_runtime_dependency 'multi_require', '~> 1.0'

  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'minitest', '~> 5.0', '< 5.11'
  spec.add_development_dependency 'minitest-colorin', '~> 0.1'
  spec.add_development_dependency 'minitest-line', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.12'
  spec.add_development_dependency 'coveralls', '~> 0.8'
  spec.add_development_dependency 'pry-nav', '~> 0.2'

  if RUBY_ENGINE == 'jruby'
    spec.add_development_dependency 'jdbc-sqlite3', '~> 3.8'
  else
    spec.add_development_dependency 'sqlite3', '~> 1.3'
  end

  if RUBY_VERSION < '2'
    spec.add_development_dependency 'term-ansicolor', '~> 1.3.0'
    spec.add_development_dependency 'tins', '~> 1.6.0'
    spec.add_development_dependency 'json', '~> 1.8'
  end
end
