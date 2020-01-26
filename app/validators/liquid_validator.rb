# frozen_string_literal: true

class LiquidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    Liquid::Template.parse(value)
  rescue Liquid::SyntaxError => e
    record.errors[attribute] << (options[:message] || "is not valid liquid: #{e.message}")
  end
end
