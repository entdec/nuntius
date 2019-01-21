$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "nuntius/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "nuntius"
  s.version     = Nuntius::VERSION
  s.authors     = ["Tom de Grunt"]
  s.email       = ["tom@degrunt.nl"]
  s.homepage    = 'https://code.entropydecelerator.com/components/nuntius'
  s.summary     = 'Messaging and notification for Ruby on Rails'
  s.description = 'Messages are defined in templates editable by users.'
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency 'liquid', '~> 4.0.0'
  s.add_dependency "rails", "~> 5.1.6"
  s.add_dependency 'pg'
end
