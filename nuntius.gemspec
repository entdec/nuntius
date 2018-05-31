$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nuntius/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nuntius"
  s.version     = Nuntius::VERSION
  s.authors     = ["Tom de Grunt"]
  s.email       = ["tom@degrunt.nl"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Nuntius."
  s.description = "TODO: Description of Nuntius."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.1.6"

  s.add_development_dependency "sqlite3"
end
