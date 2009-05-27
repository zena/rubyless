# -*- encoding: utf-8 -*-


Gem::Specification.new do |s|
  s.name = %q{rubyless}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Gaspard Bucher"]
  s.date = %q{2009-05-27}
  s.description = %q{RubyLess is an interpreter for "safe ruby". The idea is to transform some "unsafe" ruby code into safe, type checked
  ruby, eventually rewriting some variables or methods.}
  s.email = ["gaspard@teti.ch"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "PostInstall.txt", "README.rdoc"]
  
  s.files = ["History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "lib/QueryBuilder.rb", "script/console", "script/destroy", "script/generate", "test/mock/dummy_class.rb", "test/RubyLess/basic.yml", "test/RubyLess/errors.yml", "test/test_helper.rb", "test/test_RubyLess.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://zenadmin.org/en/community/module546.html}
  s.post_install_message = %q{PostInstall.txt}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{rubyless}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{RubyLess is an interpreter for "safe ruby".}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<yamltest>, [">= 0.5.0"])
    else
      s.add_dependency(%q<yamltest>, [">= 0.5.0"])
    end
  else  
    s.add_dependency(%q<yamltest>, [">= 0.5.0"])
  end
end