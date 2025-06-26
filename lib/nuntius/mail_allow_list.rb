# frozen_string_literal: true

require "mail"

module Nuntius
  class MailAllowList
    def initialize(allow_list = [])
      allow_list = [] if allow_list.blank?
      @allow_list = allow_list.map(&:downcase)
    end

    def allowed?(email)
      return true if @allow_list.blank?

      mail_to = Mail::Address.new(email.downcase)
      allow_list_match = @allow_list.detect do |allow|
        allow == (allow.include?("@") ? mail_to.to_s : mail_to.domain)
      end

      allow_list_match.present?
    end
  end
end
