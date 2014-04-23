# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

gem = Gem::Specification.new do |gem|
  gem.name          = 'image_optimize'
  gem.version       = File.open("VERSION", "r") { |f| f.read }
  gem.authors       = ['caryp']
  gem.email         = ['cary@rightscale.com']
  gem.description   = %q{Bundle a running server into a new image that will be used on next launch}
  gem.summary       = %q{Bundle a running server into a new image that will be used on next launch}
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($/).delete("")
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.add_dependency 'mime-types', '2.0'
  gem.add_dependency 'right_api_client', '1.5.15'
  gem.add_dependency 'trollop', '2.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~>2.14'
  gem.add_development_dependency 'pry'
end