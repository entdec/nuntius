# frozen_string_literal: true

module Nuntius
  # An admin page's tabs, which its block adds, for its frame (shared/_page) to show:
  #
  #   <%= nuntius_page :nuntius_admin_layouts, title: …, form: f do |page| %>
  #     <% page.tab :media do %>…<% end %>
  #   <% end %>
  #
  # A tab's label is the page's tabs.main.tab.<id>; padding: false for one its content fills (an editor, a table).
  # What's about the record (a message's state, when it was sent) goes beside them, whichever tab is shown:
  #
  #     <% page.aside do %>…<% end %>
  class Page
    Tab = Data.define(:id, :label, :padding, :content)

    attr_reader :tabs, :aside

    def initialize(view)
      @view = view
      @tabs = []
    end

    def tab(id, label: nil, padding: true, &block)
      @tabs << Tab.new(id: id, label: label || @view.t(".tabs.main.tab.#{id}"), padding: padding, content: @view.capture(&block))
      nil
    end

    def aside(&block)
      return @aside unless block

      @aside = @view.capture(&block)
      nil
    end
  end
end
