# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rubyless}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2009-06-02}
  s.email = %q{gaspard@teti.ch}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["History.txt", "Rakefile", "README.rdoc", "rubyless.gemspec", "test/mock", "test/mock/dummy_class.rb", "test/RubyLess", "test/RubyLess/basic.yml", "test/RubyLess/errors.yml", "test/RubyLess_test.rb", "test/test_helper.rb", "lib/RubyLess.rb", "lib/SafeClass.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://zenadmin.org/546}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rubyless}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{RubyLess is an interpreter for "safe ruby". The idea is to transform some "unsafe" ruby code into safe, type checked ruby, eventually rewriting some variables or methods}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
