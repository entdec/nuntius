# frozen_string_literal: true

module Nuntius
  # An email layout designed with the email editor (TessEdit). json is the
  # editor's document, mjml the MJML it exports and html that compiled. Its
  # Content block marks where the templates and campaigns using it put their
  # own content (see EmailDesign); they follow the layout when it changes.
  class Layout < ApplicationRecord
    include Nuntius::Concerns::Owned

    has_many_attached :attachments, service: Nuntius.config.active_storage_service
    has_many :templates, dependent: :restrict_with_error
    has_many :campaigns, dependent: :restrict_with_error

    validates :name, :mjml, presence: true
    validate :one_content_block
    # Those uploaded before it was saved (PendingImages), named in its design
    before_save :attach_pending_images, if: :new_record?
    before_save :compile, if: :mjml_changed?
    before_save :store_image_names, if: :json_changed?
    after_save :recompose_emails, if: :saved_change_to_mjml?
    # Its templates' and campaigns' translations are in its scope
    after_update -> { Translations.move(account_id, Layout.new(name: name_before_last_save).translation_scope, translation_scope) }, if: :saved_change_to_name?

    # What its Liquid can use (see Variables): it's rendered as part of a
    # template or a campaign, with the one that uses it
    # The subject an email in it has that has none of its own: its root's
    # Subject in the editor
    def default_subject
      json.dig("data", "subject").presence if json.is_a?(Hash)
    end

    def variable_roots
      Variables.account.merge("template" => TemplateDrop, "campaign" => CampaignDrop)
    end

    # The scope of the keys starting with a dot that its Liquid translates
    # (see I18nStore). The templates and campaigns using it start with it, so
    # its keys are theirs too.
    def translation_scope
      name.to_s.underscore.tr(" ", "_")
    end

    # Its HTML to look at, as when choosing a layout for a new template: its
    # Liquid rendered without values, its images on this host
    def preview_html
      ::Liquidum.render(html.to_s, assigns: {}, registers: {"template" => self})
    rescue => e
      Nuntius.config.logger.call.warn "Can't render the preview of layout #{id}: #{e.message}"
      html.to_s
    end

    # The metadata variables its design uses, see MetadataVariables
    def metadata_variables
      MetadataVariables.in(self, mjml)
    end

    # The images among its attachments, for the editor's Image blocks: one
    # per name, the first uploaded (see EmailImages)
    def email_images
      attachments.select { |attachment| attachment.blob.image? }.sort_by { |attachment| [attachment.created_at, attachment.id] }.uniq { |attachment| attachment.filename.to_s }
    end

    STARTING_LAYOUTS = %w[basic newsletter transactional empty].freeze

    # The attributes of a starting layout's blocks that people read: a text's
    # text, an image's alt, a menu item's label and a button's content
    STARTING_TEXT_KEYS = %w[text alt label content].freeze

    # A ready-made design to start a new layout from (config/nuntius/starting_layouts),
    # its texts in the current language
    def self.starting_document(key = "basic")
      key = "basic" unless STARTING_LAYOUTS.include?(key.to_s)
      translate_starting_texts(::JSON.parse(Engine.root.join("config/nuntius/starting_layouts/#{key}.json").read))
    end

    # The texts people read in a starting layout's document
    def self.starting_texts(node)
      case node
      when Hash then node.flat_map { |name, value| (STARTING_TEXT_KEYS.include?(name) && value.is_a?(String)) ? [value] : starting_texts(value) }.compact_blank
      when Array then node.flat_map { |child| starting_texts(child) }
      else []
      end
    end

    # Its files have them in English, each translated by its key in
    # nuntius.starting_layouts.texts, found by its English
    def self.translate_starting_texts(node, keys = I18n.t("nuntius.starting_layouts.texts", locale: :en).invert)
      case node
      when Hash
        node.to_h do |name, value|
          key = keys[value] if STARTING_TEXT_KEYS.include?(name) && value.is_a?(String)
          [name, key ? I18n.t("nuntius.starting_layouts.texts.#{key}", default: value) : translate_starting_texts(value, keys)]
        end
      when Array then node.map { |child| translate_starting_texts(child, keys) }
      else node
      end
    end

    private

    def one_content_block
      return if mjml.blank?

      EmailDesign.content_of(mjml)
      result = Nuntius::Mjml.compile(mjml)
      errors.add(:mjml, "could not be compiled: #{result.errors.join("; ")}") unless result.html
    rescue EmailDesign::Error
      errors.add(:base, "A layout needs exactly one Content block, for the content of its templates and campaigns")
    end

    def compile
      self.html = Nuntius::Mjml.compile(mjml).html
    end

    def attach_pending_images
      PendingImages.new(self).attach
    end

    # Uploaded images are kept by name only, see EmailImages
    def store_image_names
      self.json = EmailImages.new(self).normalize(json)
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
