require "rubygems"
require "rake/rdoctask"

task :default => :test

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.verbose = true
end


# BONES gem management

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'rubyless'

PROJ.name = 'rubyless'
PROJ.authors = 'Gaspard Bucher'
PROJ.email = 'gaspard@teti.ch'
PROJ.url = 'http://zenadmin.org/546'
PROJ.version = RubyLess::VERSION
PROJ.rubyforge.name = 'rubyless'

PROJ.spec.opts << '--color'
PROJ.gem.files = (
  ['History.txt', 'README.txt', 'Rakefile', 'rubyless.gemspec'] +
  ['lib', 'test'].map do |d|
    Dir.glob("#{d}/**/*").reject {|path| File.basename(path) =~ /^\./ }
  end
).flatten

PROJ.gem.dependencies << ['ruby_parser', '>= 2.0.4']
PROJ.gem.dependencies << ['sexp_processor', '>= 3.0.1']
PROJ.gem.development_dependencies << ['yamltest', '>= 0.5.3']

