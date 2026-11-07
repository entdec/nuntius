# frozen_string_literal: true

module Nuntius
  # Liquid variables that read metadata, like {{ template.metadata.logo_url }}.
  # Old layouts read their values from the template's or campaign's metadata;
  # designs in the email editor should take them from a drop instead (like
  # {{ user.account.logo_url }}), as metadata is going away.
  module MetadataVariables
    VARIABLE = /\b(template|campaign|layout)\.metadata(?:\.(\w+)|\[\s*["'](\w+)["']\s*\])/

    # The variables in the texts, like "template.metadata.logo_url", with the
    # value the record's own metadata has for them (or nil)
    def self.in(record, *texts)
      variables = texts.compact.flat_map { |text| text.scan(VARIABLE) }.map { |object, key, quoted_key| [object, key || quoted_key] }.uniq
      variables.map do |object, key|
        own = record.class.name.demodulize.underscore == object && record.respond_to?(:metadata)
        ["#{object}.metadata.#{key}", own ? (record.metadata || {})[key] : nil]
      end
    end
  end
end
