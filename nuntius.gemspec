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

  s.add_dependency 'liquor', '~> 0.1'
  s.add_dependency 'pg'
  s.add_dependency "rails", ">= 5.2"
  s.add_dependency 'webpacker', '>= 4'

  s.add_dependency 'fcm'
  s.add_dependency 'houston'
  s.add_dependency 'mail', '~> 2.6'
  s.add_dependency 'messagebird-rest'
  s.add_dependency 'parse-cron'
  s.add_dependency 'twilio-ruby', '~> 5.6'

  s.add_dependency 'inky-rb'
  s.add_dependency 'premailer'

  s.add_development_dependency 'pry', '~> 0.11'
  s.add_development_dependency 'rubocop', '~> 0.49'
end
