require 'rubygems'
require 'rake'

require(File.join(File.dirname(__FILE__), 'lib/ruby_less/info'))

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.version = RubyLess::VERSION
    gem.name = "rubyless"
    gem.summary = %Q{TODO: one-line summary of your gem}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email = "gaspard@teti.ch"
    gem.homepage = "http://zenadmin.org/546"
    gem.authors = ["Gaspard Bucher"]
    gem.add_dependency 'ruby_parser', '>= 2.0.4'
    gem.add_dependency 'sexp_processor', '>= 3.0.1'
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "yamltest", ">= 0.5.3"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rubyless #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
