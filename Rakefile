require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require './lib/porterable/version.rb'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "is_porterable"
    gem.summary = "Simple Importing and Exporting from/to CSV for Rails 3"
    gem.description = "Simple Importing and Exporting from/to CSV for Rails 3"
    gem.email = "ryanong@gmail.com"
    gem.homepage = "http://github.com/ryanong/is_porterable"
    gem.authors = ["Ryan Ong"]
    gem.add_development_dependency "yaml"
    gem.version = Porterable::Version::STRING
  end
  Jeweler::RubygemsDotOrgTasks.new

rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the is_porterable plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the is_porterable plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'IsPorterable'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
