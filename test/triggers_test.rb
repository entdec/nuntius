# frozen_string_literal: true

require "test_helper"

# Triggers are named for what happened: a state its events go to, the life
# cycle's, or its own fired by name; Nuntius.event, deprecated, as Nuntius.fire
class Nuntius::TriggersTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = User.create!(name: "test", email: "test@example.com", state: "pending")
  end

  test "a class's triggers: the states its events go to, the life cycle's, its own; their names for people" do
    assert_equal %i[active disabled created updated saved destroyed], Nuntius::Triggers.for(User)
    assert_equal %i[active disabled], Nuntius::Triggers.for(Report)
    assert_includes UserMessenger.events("User"), :active
    assert_not_includes UserMessenger.events("User"), :activate
    assert_equal "active", UserMessenger.event_label(:active, "User")
    assert_equal "created", UserMessenger.event_label(:created, "User")
  end

  test "a class's own triggers, declared with nuntiable triggers:, are fired by name" do
    # As nuntiable triggers: %i[reminded] leaves it, without adding a class to Nuntius' nuntiable ones
    model = Class.new(Report)
    model.instance_variable_set(:@_nuntius_nuntiable_options, {triggers: %i[reminded]})

    assert_equal %i[reminded], Nuntius::Triggers.for(model)
  end

  test "a trigger's templates are sent, though its messenger has no method by its name" do
    assert_not UserMessenger.method_defined?(:active)

    assert_difference -> { Nuntius::Message.where(nuntiable: @user, template: nuntius_templates(:user_activate)).count }, 1 do
      perform_enqueued_jobs(only: [Nuntius::MessengerJob]) { @user.activate! }
    end
  end

  test "a transition sends the templates for the state it goes to, not those for its event; staying sends nothing" do
    on_state = Nuntius::Template.create!(description: "state", klass: "User", transport: "mail", event: "active", to: "a@example.org", html: "Hi", account: accounts(:one))
    on_event = Nuntius::Template.create!(description: "event", klass: "User", transport: "mail", event: "activate", to: "b@example.org", html: "Hi", account: accounts(:one))

    assert [on_state, on_event].all?(&:persisted?)
    clear_enqueued_jobs
    @user.activate!

    fired = enqueued_jobs.select { |job| job["job_class"] == "Nuntius::MessengerJob" }.map { |job| job["arguments"][1] }
    assert_equal ["active"], fired - %w[updated saved]
  end

  test "Nuntius.event, deprecated, fires the one state an event goes to, the life cycle by its name now, anything else as it is" do
    assert_equal :active, Nuntius.trigger_for_event(:activate, @user)
    assert_equal :created, Nuntius.trigger_for_event(:create, @user)
    assert_equal :translationtest, Nuntius.trigger_for_event(:translationtest, accounts(:one))

    fired = []
    Nuntius.stub(:fire, ->(name, *) { fired << name }) do
      assert_output(nil, /Nuntius.fire\(:active/) { Nuntius.event(:activate, @user) }
    end
    assert_equal [:active], fired
  end

  test "Nuntius.event fails for an event that goes to several states or stays where it is" do
    model = Class.new(User) do
      def self.name = "User"
      state_machine do
        event(:remind) { transition any => same }
        event(:flip) { transition active: :disabled, disabled: :active }
      end
    end
    record = model.new

    assert_match "no other state", assert_raises(ArgumentError) { Nuntius.trigger_for_event(:remind, record) }.message
    assert_match "several states (disabled, active)", assert_raises(ArgumentError) { Nuntius.trigger_for_event(:flip, record) }.message
  end

  test "move_to_triggers! moves templates to the states their events go to, the life cycle's names and the app's own; leaves what it can't" do
    template = ->(klass, event) { Nuntius::Template.create!(description: "#{klass} #{event}", klass:, event:, transport: "mail", to: "a@example.org", html: "Hi", account: accounts(:one)) }
    activate = template.call("User", "activate")
    create = template.call("User", "create")
    active = template.call("User", "active")
    remind = template.call("User", "remind")
    welcome = template.call("User", "welcome")
    unknown = template.call("Report", "nonsense")
    custom = Nuntius::Template.create!(description: "custom", klass: "Custom", event: "order#shipped", transport: "mail", to: "a@example.org", html: "Hi", account: accounts(:one))

    left = Nuntius::Template.move_to_triggers!("User" => {"remind" => "reminded"})

    assert_equal %w[active created active reminded welcome nonsense order#shipped], [activate, create, active, remind, welcome, unknown, custom].map { |each| each.reload.event }
    mine = [activate, create, active, remind, welcome, unknown, custom].map(&:id)
    assert_equal [[welcome.id, :not_a_trigger], [unknown.id, :not_a_trigger]].sort, left.filter_map { |each, why| [each.id, why] if mine.include?(each.id) }.sort
  end
end
