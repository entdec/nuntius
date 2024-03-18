# frozen_string_literal: true

require "mail"
require "net/imap"

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
require File.expand_path("../test/dummy/config/environment.rb", __dir__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [File.expand_path("fixtures", __dir__)]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

Mail.defaults do
  delivery_method :test
end

require "webmock/minitest"
require "vcr"

WebMock.allow_net_connect!

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :faraday
  config.default_cassette_options = {record: :new_episodes, match_requests_on: [:host]}
  # config.allow_http_connections_when_no_cassette = true
end

Rails.application.routes.default_url_options[:host] = "localhost:3000"

class MockIMAPFetchData
  attr_reader :attr, :number

  def initialize(rfc822, number, flag)
    @attr = {"RFC822" => rfc822, "FLAGS" => flag}
    @number = number
  end
end

class MockIMAP
  @@connection = false
  @@mailbox = nil
  @@readonly = false
  @@marked_for_deletion = []
  @@default_examples = {
    default: (0..19).map do |i|
      MockIMAPFetchData.new("To: test#{i.to_s.rjust(2, "0")}\r\nFrom: dummy@example.com\r\nSubject: Test mail\r\nThis is body", i, "DummyFlag#{i}")
    end
  }
  @@default_examples["UTF-8"] = @@default_examples[:default].slice(0, 1)

  def self.examples(charset = nil)
    @@examples.fetch(charset || :default)
  end

  def initialize
    @@examples = {
      :default => @@default_examples[:default].dup,
      "UTF-8" => @@default_examples["UTF-8"].dup
    }
  end

  def login(_user, _password)
    @@connection = true
  end

  def disconnect
    @@connection = false
  end

  def select(mailbox)
    @@mailbox = mailbox
    @@readonly = false
  end

  def examine(mailbox)
    select(mailbox)
    @@readonly = true
  end

  def uid_search(_keys, charset = nil)
    [*(0..self.class.examples(charset).size - 1)]
  end

  def uid_fetch(set, _attr)
    [self.class.examples[set]]
  end

  def uid_store(set, attr, flags)
    @@marked_for_deletion << set if attr == "+FLAGS" && flags.include?(Net::IMAP::DELETED)
  end

  def expunge
    @@marked_for_deletion.reverse_each do |i|
      # start with highest index first
      self.class.examples.delete_at(i)
    end
    @@marked_for_deletion = []
  end

  # test only
  def self.mailbox
    @@mailbox
  end

  # test only
  def self.readonly?
    @@readonly
  end

  def self.disconnected?
    @@connection == false
  end

  def disconnected?
    @@connection == false
  end
end

class Net::IMAP
  def self.new(*_args)
    MockIMAP.new
  end
end

class QuxMessageBox < Nuntius::BaseMessageBox
  transport :mail
  provider :imap

  class << self
    def hatseflats(wut = nil)
      @hatseflats = wut if wut
      @hatseflats
    end
  end

  @hatseflats = nil

  route(:to, /.+/, to: :smurrefluts)

  def smurrefluts
    QuxMessageBox.hatseflats("hatseflats")
  end
end

class FooMessageBox < Nuntius::BaseMessageBox
  transport :sms
  provider :twilio

  route :to, /\+31.*/, to: :dutchies
end

class BarMessageBox < Nuntius::BaseMessageBox
  transport :mail
  provider :imap
end
