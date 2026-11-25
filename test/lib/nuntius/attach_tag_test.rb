# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module Nuntius
  # {% attach %}: what it attaches to the message being made
  class AttachTagTest < ActiveSupport::TestCase
    include EmailDesignHelper

    def render(source, message:, assigns: {})
      ::Liquidum.render(source, assigns: assigns, registers: {"message" => message})
    end

    def build_message
      Message.new(transport: "mail", provider: "smtp", to: "user@example.com", subject: "Test", text: "Body")
    end

    def layout_with_files
      layout = create_layout
      layout.attachments.attach(io: StringIO.new("Terms"), filename: "terms.txt", content_type: "text/plain")
      layout.attachments.attach(io: StringIO.new("Prices"), filename: "prices.txt", content_type: "text/plain")
      layout
    end

    # Its attachments, stored as the message is
    def attached(message)
      message.save!
      message.attachments.map { |attachment| [attachment.filename.to_s, attachment.download] }.sort
    end

    test "a stored file, or each of a record's" do
      layout = layout_with_files

      message = build_message
      assert_equal "", render("{% attach layout.attachments.first %}", message:, assigns: {"layout" => layout})
      assert_equal [%w[terms.txt Terms]], attached(message)

      message = build_message
      render("{% attach layout.attachments %}", message:, assigns: {"layout" => layout})
      assert_equal [%w[prices.txt Prices], %w[terms.txt Terms]], attached(message)
    end

    test "what a drop makes: content as a string or an IO, one or a list, by symbol or string keys" do
      message = build_message
      card = {content: "Front", filename: "card.txt", content_type: "text/plain"}
      back = {"content" => StringIO.new("Back"), "filename" => "back.txt", "content_type" => "text/plain"}

      render("{% attach card %}{% attach cards %}", message:, assigns: {"card" => card, "cards" => [back]})

      assert_equal [%w[back.txt Back], %w[card.txt Front]], attached(message)
      assert_equal %w[text/plain], message.attachments.map(&:content_type).uniq
    end

    test "nothing for nothing, or for what it can't attach" do
      message = build_message

      render("{% attach nothing %}{% attach empty %}{% attach number %}{% attach no_content %}", message:,
        assigns: {"nothing" => nil, "empty" => [], "number" => 3, "no_content" => {filename: "x.txt"}})

      assert_empty message.attachments
    end

    test "a URL over http(s), never a file of the server" do
      message = build_message
      urls = []

      message.stub(:add_attachment, ->(options) { urls << options[:url] }) do
        render("{% attach 'https://example.com/a.pdf' %}{% attach 'HTTP://example.com/b.pdf' %}{% attach 'file:///etc/hosts' %}{% attach '/etc/hosts' %}{% attach url %}",
          message:, assigns: {"url" => "file:///etc/passwd"})
      end

      assert_equal %w[https://example.com/a.pdf HTTP://example.com/b.pdf], urls
    end

    test "nothing without a message to attach to, as in a preview" do
      assert_equal "", ::Liquidum.render("{% attach card %}", assigns: {"card" => {content: "x", filename: "x.txt"}})
    end
  end
end
