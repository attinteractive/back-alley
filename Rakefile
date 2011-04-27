require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "back-alley"
  gem.homepage = "http://github.com/aq1018/back-alley"
  gem.license = "MIT"
  gem.summary = %Q{Restful LWES proxy server that traffics LWES events from HTTP to UDP.}
  gem.description = %Q{Back Alley is an LWES HTTP proxy that traffics LWES Event from HTTP to UDP. Back Alley helps you to send your LWES events to UDP endpoints, however, the design goal is to be a pure proxy, and it doesn't check the validity of format against LWES event schema. Thus the Back Alley doesn't care about what you traffic.}
  gem.email = "aqian@attinteractive.com"
  gem.authors = ["Aaron Qian"]
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

require 'roodi'
require 'roodi_task'
RoodiTask.new do |t|
  t.verbose = false
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
