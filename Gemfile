# frozen_string_literal: true

source 'https://rubygems.org'

# Declare your gem's dependencies in nuntius.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]

git_source(:entdec) { |repo_name| "git@code.entropydecelerator.com:#{repo_name}.git" }

gem 'action_table', entdec: 'components/action_table', tag: '0.2.11'
gem 'auxilium', entdec: 'components/auxilium', tag: '0.1.3'
gem 'evento', entdec: 'components/evento', tag: '0.1.2'
gem 'liquor', entdec: 'components/liquor', tag: '0.6.2'
gem 'pry'
gem 'trado', entdec: 'components/trado', tag: '0.1.12'

gem 'irb', '~> 1.0'
gem 'solargraph'

gem 'sidekiq'

group :test do
  gem 'vcr', '~> 4.0', require: false
  gem 'webmock', '~> 3.3', require: false
end
