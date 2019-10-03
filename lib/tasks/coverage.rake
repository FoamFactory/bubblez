require 'rspec/core/rake_task'
require 'simplecov'

namespace :spec do
  desc "Create rspec coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].execute
  end

  namespace :coverage do
    desc 'View coverage information'
    task :view => [:coverage] do
      `open coverage/index.html` # This only works if running OS X.
    end
  end
end
