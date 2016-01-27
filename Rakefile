require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :server

desc "Exec bot server"
task :server do
  sh "ruby -I lib lib/bot.rb"
end
