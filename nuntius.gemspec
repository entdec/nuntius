# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'nuntius/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'nuntius'
  s.version     = Nuntius::VERSION
  s.authors     = ['Tom de Grunt']
  s.email       = ['tom@degrunt.nl']
  s.homepage    = 'https://github.com/entdec/nuntius'
  s.summary     = 'Messaging and notification for Ruby on Rails'
  s.description = 'Messages are defined in editable liquid templates.'
  s.license     = 'MIT'
  s.required_ruby_version = Gem::Requirement.new('>= 2.6.5')

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'apnotic', '1.7.0'
  s.add_dependency 'auxilium', '~> 3'
  s.add_dependency 'aws-sdk-sns', '~> 1.56'
  s.add_dependency 'evento', '~> 0'
  s.add_dependency 'fcm', '~> 1.0'
  s.add_dependency 'houston', '~> 2.4'
  s.add_dependency 'httpclient', '~> 2.8.3'
  s.add_dependency 'i18n', '~> 1.8.5'
  s.add_dependency 'inky-rb', '~> 1.4'
  s.add_dependency 'labelary'
  s.add_dependency 'liquidum'
  s.add_dependency 'mail', '~> 2'
  s.add_dependency 'messagebird-rest'
  s.add_dependency 'net-imap'
  s.add_dependency 'net-smtp'
  s.add_dependency 'parse-cron'
  s.add_dependency 'pg'
  s.add_dependency 'premailer'
  s.add_dependency 'rails', '>= 6'
  s.add_dependency 'rubyzip', '> 2'
  s.add_dependency 'servitium', '~> 1'
  s.add_dependency 'slack-ruby-client'
  s.add_dependency 'state_machines-activerecord'
  s.add_dependency 'twilio-ruby', '~> 5'

  s.add_development_dependency 'pry', '~> 0.11'
  s.add_development_dependency 'rubocop', '~> 1'
end
