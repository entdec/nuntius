# frozen_string_literal: true

module Nuntius
  # An action on an admin page (New template, Resend, …), as data: the page's frame (shared/_index, shared/_page,
  # which the host app may draw its own way) shows it, as a button or in its own menu.
  #
  #   method:  a request other than GET it makes (:post), confirm: what it asks first
  #   submit:  a button of the page's form, sending it to link instead (Send test)
  PageAction = Data.define(:id, :label, :link, :icon, :method, :confirm, :submit) do
    def initialize(id:, label:, link:, icon: nil, method: nil, confirm: nil, submit: false)
      super
    end
  end
end
