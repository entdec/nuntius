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

gem 'liquor', entdec: 'components/liquor', tag: '0.4.0'
gem 'trado', entdec: 'components/trado', branch: :master
gem 'pry'

gem "irb", "~> 1.0"
