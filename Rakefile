require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run RuboCop"
task :rubocop do
  sh "rubocop"
end

desc "Generate documentation"
task :yard do
  sh "yard doc"
end

desc "Run all checks"
task :check => [:rubocop, :spec]

desc "Run examples (public API only)"
task :examples do
  sh "ruby examples/public_api_example.rb"
  sh "ruby examples/error_handling_example.rb"
end

desc "Install gem locally"
task :install do
  sh "gem build buda_api.gemspec"
  sh "gem install buda_api-*.gem"
end

desc "Clean build artifacts"
task :clean do
  sh "rm -f buda_api-*.gem"
  sh "rm -rf doc/"
end