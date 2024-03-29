# -*- encoding: utf-8 -*-

$:.push File.expand_path("../lib", __FILE__)
require "{name}/version"

Gem::Specification.new do |s|
  s.name        = "{name}"
  s.version     = {class_name}_Version
  s.authors     = ["{username}"]
  s.email       = ["{email}"]
  s.homepage    = "https://github.com/{username}/{name}"
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'bacon'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'Bacon_Colored'
  s.add_development_dependency 'pry'
  
  # Specify any dependencies here; for example:
  # s.add_runtime_dependency 'rest-client'
end
