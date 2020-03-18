# frozen_string_literal: true

module Nuntius
  # Stores individual messages to individual recipients
  #
  #
  # Nuntius will have messages in states:
  #   pending - nothing done yet
  #   sent - we've sent it on to the provider
  #   delivered - have delivery confirmation
  #   undelivered - have confirmation of non-delivery
  # Not all transports may provide all states
  class Message < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped

    has_and_belongs_to_many :attachments, :class_name => 'Attachment'

    belongs_to :campaign, optional: true
    belongs_to :template, optional: true
    belongs_to :parent_message, class_name: 'Message', optional: true
    belongs_to :nuntiable, polymorphic: true, optional: true

    validates :transport, presence: true

    before_destroy :cleanup_attachments

    # Weird loading sequence error, is fixed by the lib/nuntius/helpers
    # begin
    #   has_many_attached :attachments
    # rescue NoMethodError
    # end

    def pending?
      status == 'pending'
    end

    def sent?
      status == 'sent'
    end

    def delivered?
      status == 'delivered'
    end

    def undelivered?
      status == 'undelivered'
    end

    # Removes only pending child messages
    def cleanup!
      Nuntius::Message.where(status: 'pending').where(parent_message: self).destroy_all
    end

    def cleanup_attachments
      attachments.each do |attachment|
        attachment.destroy if attachment.messages.where.not(id: id).blank?
      end
    end

    def nuntius_provider(message)
      klass = Nuntius::BaseProvider.class_from_name(provider, transport)
      klass ||= Nuntius::BaseProvider
      klass.new(message)
    end

    #
    # Convenience method to easily send messages without having a template
    #
    def deliver_as(transport)
      klass = BaseTransport.class_from_name(transport).new
      klass.deliver(self)
      self
    end
  end
end
