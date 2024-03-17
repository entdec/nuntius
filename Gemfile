# frozen_string_literal: true

source "https://rubygems.org"

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

git_source(:entdec) { |repo_name| "git@github.com:entdec/#{repo_name}.git" }

gem "liquidum", entdec: "liquidum", branch: "main"
gem "action_table", entdec: "action_table", tag: "0.2.37"
gem "trado", entdec: "trado", tag: "0.1.16"

gem "irb", "~> 1"

gem "sidekiq"

group :test do
  gem "vcr", "~> 6.0", require: false
  gem "webmock", "~> 3.3", require: false
end
