# frozen_string_literal: true

require "test_helper"

module Nuntius
  class TemplateAddresseesTest < ActiveSupport::TestCase
    setup do
      @account = accounts(:one)
      @account.users.create!(name: "Ann", email: "ann@example.com")
      @account.users.create!(name: "Bob", email: "bob@example.com")
    end

    test "a message for each address in the To, with the address as to" do
      template = Template.new(transport: "mail", to: "a@example.com, b@example.com", subject: "Hi {{ to }}")

      messages = template.new_messages({})

      assert_equal %w[a@example.com b@example.com], messages.map(&:to)
      assert_equal ["Hi a@example.com", "Hi b@example.com"], messages.map(&:subject)
    end

    test "a message for each drop in the To, rendered with the drop as to" do
      template = Template.new(transport: "mail", to: "{{ account.users }}", subject: "Hi {{ to.name }}", text: "Dear {{ to.name }} of {{ account.name }}")

      messages = template.new_messages(@account, {"account" => @account})

      assert_equal %w[ann@example.com bob@example.com], messages.map(&:to).sort
      assert_equal ["Hi Ann", "Hi Bob"], messages.map(&:subject).sort
      assert_includes messages.map(&:text), "Dear Ann of #{@account.name}"
    end

    test "a single drop in the To" do
      user = @account.users.first
      template = Template.new(transport: "mail", to: "{{ user }}", subject: "Hi {{ to.name }}")

      messages = template.new_messages(user, {"user" => user})

      assert_equal [user.email], messages.map(&:to)
      assert_equal ["Hi #{user.name}"], messages.map(&:subject)
    end

    test "hashes in the To" do
      template = Template.new(transport: "sms", to: "{{ contacts }}", text: "Hi {{ to.name }}")

      messages = template.new_messages({}, {"contacts" => [{"name" => "Ann", "phone_number" => "+31600000001"}, {"name" => "Bob", "phone_number" => ""}]})

      assert_equal ["+31600000001"], messages.map(&:to)
      assert_equal ["Hi Ann"], messages.map(&:text)
    end

    test "a variable rendering to addresses still works" do
      template = Template.new(transport: "mail", to: "{{ user.email }}", subject: "Hi")
      user = @account.users.first

      assert_equal [user.email], template.new_messages(user, {"user" => user}).map(&:to)
    end

    test "no messages without addressees" do
      template = Template.new(transport: "mail", to: "{{ nobody }}")

      assert_empty template.new_messages({})
    end

    test "new_message is deprecated, and gives the first message" do
      template = Template.new(transport: "mail", to: "a@example.com, b@example.com")

      message = nil
      assert_output(nil, /Template#new_message is deprecated/) { message = template.new_message({}) }
      assert_equal "a@example.com", message.to
    end

    test "an on demand template is sent to an object when asked, and gives its messages" do
      template = Template.create!(klass: "Account", based_on: "on_demand", transport: "mail", description: "news", to: "{{ account.users }}", from: "from@example.com", subject: "Hi {{ to.name }}", text: "Body", enabled: true, account: @account)

      messages = template.deliver_to(@account)

      assert_equal %w[ann@example.com bob@example.com], messages.map(&:to).sort
      assert_equal [@account], messages.map(&:nuntiable).uniq
      assert_equal messages.map(&:id).sort, Nuntius::Message.where(template: template).pluck(:id).sort
      assert_equal [template], Template.on_demand.to_a
      template.update!(to: "{{ account.nothing }}")
      assert_empty template.deliver_to(@account)
    end

    test "who sends it can say whom it goes to and from whom instead, as its own To and From" do
      template = Template.create!(klass: "Account", based_on: "on_demand", transport: "mail", description: "news", to: "{{ account.users }}", from: "info@example.com", subject: "Hi {{ to.name }}", text: "Body", enabled: true, account: @account)

      to_board = template.deliver_to(@account, to: "board@example.com, {{ account.name | downcase }}@example.com", from: "{{ account.name | downcase }}-sponsors@example.com")
      assert_equal ["board@example.com", "#{@account.name.downcase}@example.com"], to_board.map(&:to)
      assert_equal ["#{@account.name.downcase}-sponsors@example.com"], to_board.map(&:from).uniq

      ann = @account.users.find_by!(name: "Ann")
      to_ann = template.new_messages(@account, {"account" => @account, "ann" => ann}, to: "{{ ann }}")
      assert_equal [["ann@example.com", "Hi Ann"]], to_ann.map { |message| [message.to, message.subject] }

      own = template.deliver_to(@account, to: "", from: nil)
      assert_equal [%w[ann@example.com bob@example.com], ["info@example.com"]], [own.map(&:to).sort, own.map(&:from).uniq]
    end

    test "its conditions keep it from being sent, unless who sends it leaves them out" do
      template = Template.create!(klass: "Account", based_on: "on_demand", transport: "mail", description: "news", to: "a@example.com", from: "from@example.com", subject: "Hi", text: "Body", enabled: true, account: @account,
        conditions: {"match" => "all", "rules" => [{"variable" => "account.name", "operator" => "is", "value" => "Nobody"}]})

      assert_equal [], template.deliver_to(@account)
      assert_equal ["a@example.com"], template.deliver_to(@account, conditions: false).map(&:to)
    end

    test "who sends it can say what sent its messages, their source, besides what they're about" do
      template = Template.create!(klass: "Account", based_on: "on_demand", transport: "mail", description: "news", to: "a@example.com", from: "from@example.com", subject: "Hi", text: "Body", enabled: true, account: @account)
      sender = @account.users.find_by!(name: "Ann")

      messages = template.deliver_to(@account, source: sender)

      assert_equal [[@account, sender]], messages.map { |message| [message.reload.nuntiable, message.source] }
      assert_nil template.deliver_to(@account).sole.source
    end

    test "the messenger dispatches a message per addressee" do
      template = Template.create!(klass: "Account", event: "created", transport: "mail", description: "created", to: "{{ account.users }}", from: "from@example.com", subject: "Hi {{ to.name }}", text: "Body", enabled: true, account: @account)

      AccountMessenger.new(@account, :created, {}).dispatch([template])

      messages = Nuntius::Message.where(template: template)
      assert_equal %w[ann@example.com bob@example.com], messages.map(&:to).sort
      assert_equal ["Hi Ann", "Hi Bob"], messages.map(&:subject).sort
    end
  end
end
