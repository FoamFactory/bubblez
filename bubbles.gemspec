# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bubbles/version'

Gem::Specification.new do |spec|
  spec.name          = Bubbles::VersionInformation.package_name
  spec.version       = Bubbles::VersionInformation.version_name
  spec.date        = Date.today.strftime("%Y-%m-%d")
  spec.summary     = 'FoamFactory REST Client'
  spec.homepage    = 'http://www.foamfactorybrewing.com'
  spec.description = 'The client for the API controlling the FoamFactory application backend'
  spec.authors     = ['Scott Johnson']
  spec.email       = 'jaywir3@gmail.com'
  spec.files       = %w(lib/bubbles.rb lib/bubbles/RestEnvironment.rb lib/bubbles/version.rb)
  spec.license     = 'MPL-2.0'

  # spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.1"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 3.0"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_dependency "addressable", "~> 2.5"
  spec.add_dependency "rest-client", "~> 2.0"
end