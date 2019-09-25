# frozen_string_literal: true

desc 'Release a new version'
task :release do
  version_file = './lib/nuntius/version.rb'
  File.open(version_file, 'w') do |file|
    file.puts <<~EOVERSION
      # frozen_string_literal: true

      module Nuntius
        VERSION = '#{Nuntius::VERSION.split('.').map(&:to_i).tap { |parts| parts[2] += 1 }.join('.')}'
      end
    EOVERSION
  end
  module Nuntius
    remove_const :VERSION
  end
  load version_file
  puts "Updated version to #{Nuntius::VERSION}"

  `git commit lib/nuntius/version.rb -m "Version #{Nuntius::VERSION}"`
  `git push`
  `git tag #{Nuntius::VERSION}`
  `git push --tags`
end
