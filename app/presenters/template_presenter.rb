# frozen_string_literal: true

class TemplatePresenter < ApplicationPresenter
  def all_events
    events = []
    Nuntius.config.nuntiable_class_names.each do |class_name|
      next if class_name == 'Custom'

      Nuntius::BaseMessenger.messenger_for_class(class_name).instance_methods(false).each do |m|
        events << [m, m, { 'data-chain': class_name }]
      end
    end
    events.sort_by(&:first)
  end
end
