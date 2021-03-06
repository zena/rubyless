# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rubyless}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2013-11-21}
  s.description = %q{RubyLess is an interpreter for "safe ruby". The idea is to transform some "unsafe" ruby code into safe, type checked ruby, eventually rewriting some variables or methods.}
  s.email = %q{gaspard@teti.ch}
  s.extra_rdoc_files = [
    "README.rdoc",
    "TODO"
  ]
  s.files = [
    "History.txt",
    "README.rdoc",
    "Rakefile",
    "TODO",
    "lib/ruby_less.rb",
    "lib/ruby_less/basic_types.rb",
    "lib/ruby_less/error.rb",
    "lib/ruby_less/info.rb",
    "lib/ruby_less/no_method_error.rb",
    "lib/ruby_less/processor.rb",
    "lib/ruby_less/safe_class.rb",
    "lib/ruby_less/signature_hash.rb",
    "lib/ruby_less/syntax_error.rb",
    "lib/ruby_less/typed_method.rb",
    "lib/ruby_less/typed_string.rb",
    "lib/rubyless.rb",
    "rails/init.rb",
    "rubyless.gemspec",
    "test/RubyLess/active_record.yml",
    "test/RubyLess/basic.yml",
    "test/RubyLess/errors.yml",
    "test/RubyLess/hash.yml",
    "test/RubyLess/multiline.yml",
    "test/RubyLess/string.yml",
    "test/RubyLess/time.yml",
    "test/RubyLess_test.rb",
    "test/mock/active_record_mock.rb",
    "test/mock/dummy_class.rb",
    "test/mock/dummy_module.rb",
    "test/mock/property_column.rb",
    "test/safe_class_test.rb",
    "test/signature_hash_test.rb",
    "test/test_helper.rb",
    "test/typed_method_test.rb",
    "test/typed_string_test.rb"
  ]
  s.homepage = %q{http://zenadmin.org/546}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{RubyLess is an interpreter for "safe ruby"}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby_parser>, ["~> 2.3.1"])
      s.add_runtime_dependency(%q<sexp_processor>, [">= 3.0.1"])
      s.add_development_dependency(%q<shoulda>, [">= 0"])
      s.add_development_dependency(%q<yamltest>, [">= 0.6.0"])
    else
      s.add_dependency(%q<ruby_parser>, ["~> 2.3.1"])
      s.add_dependency(%q<sexp_processor>, [">= 3.0.1"])
      s.add_dependency(%q<shoulda>, [">= 0"])
      s.add_dependency(%q<yamltest>, [">= 0.6.0"])
    end
  else
    s.add_dependency(%q<ruby_parser>, ["~> 2.3.1"])
    s.add_dependency(%q<sexp_processor>, [">= 3.0.1"])
    s.add_dependency(%q<shoulda>, [">= 0"])
    s.add_dependency(%q<yamltest>, [">= 0.6.0"])
  end
end

