# frozen_string_literal: true

module Nuntius
  # An email layout designed with the email editor (TessEdit). json is the
  # editor's document, mjml the MJML it exports and html that compiled. Its
  # Content block marks where the templates and campaigns using it put their
  # own content (see EmailDesign); they follow the layout when it changes.
  class Layout < ApplicationRecord
    include Nuntius::Concerns::MetadataScoped
    include Nuntius::Concerns::Yamlify

    has_many_attached :attachments, service: Nuntius.config.active_storage_service
    has_many :templates, dependent: :restrict_with_error
    has_many :campaigns, dependent: :restrict_with_error

    validates :name, :mjml, presence: true
    validate :one_content_block
    before_save :compile, if: :mjml_changed?
    after_save :recompose_emails, if: :saved_change_to_mjml?

    yamlify :metadata

    # The images among its attachments, for the editor's Image blocks
    def email_images
      attachments.select { |attachment| attachment.blob.image? }
    end

    STARTING_LAYOUTS = %w[basic newsletter transactional empty].freeze

    # A ready-made design to start a new layout from (config/nuntius/starting_layouts)
    def self.starting_document(key = "basic")
      key = "basic" unless STARTING_LAYOUTS.include?(key.to_s)
      ::JSON.parse(Engine.root.join("config/nuntius/starting_layouts/#{key}.json").read)
    end

    private

    def one_content_block
      return if mjml.blank?

      EmailDesign.content_of(mjml)
      result = TessEdit.compile(mjml)
      errors.add(:mjml, "could not be compiled: #{result.errors.join("; ")}") unless result.html
    rescue EmailDesign::Error
      errors.add(:base, "A layout needs exactly one Content block, for the content of its templates and campaigns")
    end

    def compile
      self.html = TessEdit.compile(mjml).html
    end

    # Templates and campaigns not sent yet follow the layout. A failure rolls
    # the layout's change back, so nothing ends up with a broken email.
    def recompose_emails
      emails = templates.where.not(mjml: nil).to_a + campaigns.where(state: "draft").where.not(mjml: nil).to_a
      emails.each do |email|
        email.layout = self
        email.recompose
        next if email.save

        errors.add(:base, "#{email.class.model_name.human} #{email.try(:description) || email.try(:name)} could not follow the layout: #{email.errors.full_messages.to_sentence}")
        raise ActiveRecord::Rollback
      end
    end
  end
end
