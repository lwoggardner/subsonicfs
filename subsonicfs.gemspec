# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'subsonicfs/version'

Gem::Specification.new do |gem|
  gem.name          = "subsonicfs"
  gem.version       = SubsonicFS::VERSION
  gem.authors       = ["lwoggardner"]
  gem.email         = ["grant@lastweekend.com.au"]
  gem.description   = %q{A filesystem to expose Subsonic playlists}
  gem.summary       = %q{Uses the SubSonic REST API to interact with the server}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("rfusefs", "~> 1.0.3.RC0")
  gem.add_dependency ("rest-client")
end
