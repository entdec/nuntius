# frozen_string_literal: true

module Nuntius
  class TimebasedEventsRunner < ApplicationRunner
    def perform
      Nuntius::Template.where.not(interval: nil).each do |template|
        messenger = Nuntius::BaseMessenger.messenger_for_class(template.klass)

        messenger.timebased_scope_for(template).each do |object|
          Nuntius.with(object).message(template.event)
        end
      end
    end
  end
end
