# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "nuntius/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "nuntius"
  s.version = Nuntius::VERSION
  s.authors = ["Tom de Grunt"]
  s.email = ["tom@degrunt.nl"]
  s.homepage = "https://github.com/entdec/nuntius"
  s.summary = "Messaging and notification for Ruby on Rails"
  s.description = "Messages are defined in editable liquid templates."
  s.license = "MIT"
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.5")

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_runtime_dependency "apnotic", "1.7.0"
  s.add_runtime_dependency "auxilium", "~> 3"
  s.add_runtime_dependency "aws-sdk-sns", "~> 1.56"
  s.add_runtime_dependency "fcm", "~> 1.0"
  s.add_runtime_dependency "houston", "~> 2.4"
  s.add_runtime_dependency "faraday", ">= 2.9"
  s.add_runtime_dependency "faraday-follow_redirects", "~> 0"
  s.add_runtime_dependency "i18n", "~> 1.8.5"
  s.add_runtime_dependency "inky-rb", "~> 1.4"
  s.add_runtime_dependency "labelary", "~> 0.5"
  s.add_runtime_dependency "liquidum", "~> 1"
  s.add_runtime_dependency "mail", "~> 2"
  s.add_runtime_dependency "messagebird-rest"
  s.add_runtime_dependency "net-imap"
  s.add_runtime_dependency "net-smtp"
  s.add_runtime_dependency "parse-cron", "~> 0.1"
  s.add_runtime_dependency "pg"
  s.add_runtime_dependency "premailer", "~> 1.23"
  s.add_runtime_dependency "rails", ">= 7"
  s.add_runtime_dependency "rubyzip", "> 2"
  s.add_runtime_dependency "servitium", "~> 1"
  s.add_runtime_dependency "slack-ruby-client"
  s.add_runtime_dependency "state_machines-activerecord"
  s.add_runtime_dependency "twilio-ruby", "~> 7.0.2"
  s.add_runtime_dependency "smstools_api", "~> 0.1.4"
  s.add_runtime_dependency "slim-rails", "~> 3.6"

  s.add_development_dependency "pry", "~> 0"
  s.add_development_dependency "debug", "~> 0"
  s.add_development_dependency "rubocop", "~> 1"
  s.add_development_dependency "standard", "~> 1"
end
