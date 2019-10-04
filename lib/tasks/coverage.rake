require 'rspec/core/rake_task'
require 'simplecov'
require 'os'

namespace :spec do
  desc "Create rspec coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].execute
  end

  namespace :coverage do
    desc 'View coverage information'
    task :view => [:coverage] do
      if OS.mac?
        `open coverage/index.html`
      elsif OS.posix?
        `sensible-browser coverage/index.html`
      end
    end
  end
end
