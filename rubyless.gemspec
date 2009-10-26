# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rubyless}
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2009-10-26}
  s.description = %q{RubyLess is an interpreter for "safe ruby". The idea is to transform some "unsafe" ruby code into safe, type checked
ruby, eventually rewriting some variables or methods.}
  s.email = %q{gaspard@teti.ch}
  s.extra_rdoc_files = ["History.txt", "README.txt"]
  s.files = ["History.txt", "README.txt", "Rakefile", "rubyless.gemspec", "lib/basic_types.rb", "lib/processor.rb", "lib/rubyless.rb", "lib/safe_class.rb", "lib/typed_string.rb", "test/mock", "test/mock/active_record_mock.rb", "test/mock/dummy_class.rb", "test/RubyLess", "test/RubyLess/active_record.yml", "test/RubyLess/basic.yml", "test/RubyLess/errors.yml", "test/RubyLess_test.rb", "test/test_helper.rb"]
  s.homepage = %q{http://zenadmin.org/546}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rubyless}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{RubyLess is an interpreter for "safe ruby"}
  s.test_files = ["test/test_helper.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<ruby_parser>, [">= 2.0.4"])
      s.add_runtime_dependency(%q<sexp_processor>, [">= 3.0.1"])
      s.add_development_dependency(%q<bones>, [">= 2.5.1"])
      s.add_development_dependency(%q<yamltest>, [">= 0.5.3"])
    else
      s.add_dependency(%q<ruby_parser>, [">= 2.0.4"])
      s.add_dependency(%q<sexp_processor>, [">= 3.0.1"])
      s.add_dependency(%q<bones>, [">= 2.5.1"])
      s.add_dependency(%q<yamltest>, [">= 0.5.3"])
    end
  else
    s.add_dependency(%q<ruby_parser>, [">= 2.0.4"])
    s.add_dependency(%q<sexp_processor>, [">= 3.0.1"])
    s.add_dependency(%q<bones>, [">= 2.5.1"])
    s.add_dependency(%q<yamltest>, [">= 0.5.3"])
  end
end
