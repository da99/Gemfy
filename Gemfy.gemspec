# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "Gemfy/version"

Gem::Specification.new do |s|
  s.name        = "Gemfy"
  s.version     = Gemfy::VERSION
  s.authors     = ["da99"]
  s.email       = ["i-hate-spam-45671204@mailinator.com"]
  s.homepage    = ""
  s.summary     = %q{Gem create/update for megauni gems.}
  s.description = %q{Personal gem creator for megauni-related gems.}

  s.add_runtime_dependency 'Git_Repo'
  s.add_development_dependency 'bacon'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'Bacon_Colored'
  s.add_development_dependency 'Bacon_FS'

  s.rubyforge_project = "Gemfy"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
