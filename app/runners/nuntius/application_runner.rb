# frozen_string_literal: true

module Nuntius
  class ApplicationRunner
    def call
      rescued('Runner') do
        setup_logging(self.class.name)
        only_once do
          random_delay
          perform
        end
      end
    end

    protected

    def setup_logging(name)
      Praesens.initiating_class = name
      if Rails.env.staging? || Rails.env.testing?
        Rails.logger = ActiveSupport::TaggedLogging.new(RemoteSyslogLogger.new('159.69.210.23', 51_400, program: name.truncate(32)))
        Rails.logger.level = Logger::INFO
      elsif Rails.env.production?
        Rails.logger = ActiveSupport::TaggedLogging.new(RemoteSyslogLogger.new('172.16.22.95', 51_400, program: name.truncate(32)))
        Rails.logger.level = Logger::INFO
      end
    end

    def rescued(name)
      yield
    rescue StandardError => e
      log(:error, "Exception processing (#{name}): #{e.message}")
      log(:error, e.backtrace.join("\n"))
    end

    def per_channel
      Channel.all.order(:name).each do |channel|
        rescued("Channel #{channel.id}") do
          yield channel
        end
      end
    end

    def log(severity, message, options = {})
      if options[:exception]
        message += " (#{options[:exception].message})"
        message += "\n" + options[:exception].backtrace.join("\n")
      end

      Rails.logger.send(severity, message)
      puts message if severity == :error
    end

    def only_once
      file_name = "/tmp/runners_#{self.class.name}"
      raise StandardError, 'already running' if File.exist?(file_name)

      file = File.new(file_name, 'wb')
      file.puts "Started #{Time.now}"
      begin
        yield
      ensure
        begin
          file.close
          File.delete(file_name)
        rescue StandardError
          log :error, 'could not remove lock file.'
        end
      end
    end

    def random_delay
      delay = rand(10)
      log :info, "Sleeping for #{delay}"
      sleep delay
    end

    class << self
      delegate :call, to: :new
    end
  end
end
