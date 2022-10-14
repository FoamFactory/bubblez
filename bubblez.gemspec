# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bubblez/version'

Gem::Specification.new do |spec|
  spec.name          = Bubblez::VersionInformation.package_name
  spec.version       = Bubblez::VersionInformation.version_name
  spec.date        = Date.today.strftime("%Y-%m-%d")
  spec.summary     = 'Bubblez REST Client'
  spec.homepage    = 'https://github.com/FoamFactory/bubblez'
  spec.authors     = ['Scott Johnson']
  spec.email       = 'jaywir3@gmail.com'
  spec.files       = %w(lib/bubblez.rb lib/bubblez/rest_environment.rb lib/bubblez/version.rb)
  spec.license     = 'MPL-2.0'
  spec.summary       = %q{A gem for easily defining client REST interfaces in Ruby}
  spec.description   = %q{Retrofit, by Square, allows you to easily define annoations that will generate the necessary boilerplate code for your REST interfaces. Bubblez is a Gem that seeks to bring a similar style of boilerplate generation to Ruby.}

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
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

  spec.add_development_dependency "bundler", "~> 2.3.23"
  spec.add_development_dependency 'rake', '~> 12.3', '>= 12.3.3'
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.1"
  spec.add_development_dependency "simplecov", "~> 0.16"
  spec.add_development_dependency "webmock", "~> 3.5"
  spec.add_development_dependency "vcr", "~> 3.0"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "os", "~> 1.1.4"
  spec.add_dependency "addressable", "~> 2.5"
  spec.add_dependency "rest-client", "~> 2.0"
end
