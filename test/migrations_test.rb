# frozen_string_literal: true

require "test_helper"
require Nuntius::Engine.root.join("db/migrate/20261107100000_create_nuntius_email_layouts")

class MigrationsTest < ActiveSupport::TestCase
  test "the email layouts migration names the campaigns that aren't sent, and accepts cancelled ones" do
    valentines = nuntius_campaigns(:valentines_day)
    nuntius_campaigns(:xmas).update_column(:state, "cancelled")
    Nuntius::Message.create!(transport: "mail", to: "romeo@example.com", campaign: valentines, state: "sent")
    Nuntius::Message.create!(transport: "mail", to: "juliet@example.com", campaign: valentines)
    valentines.update_column(:state, "sending")

    error = assert_raises(ActiveRecord::MigrationError) { refuse_unsent_campaigns }

    assert_includes error.message, "- Valentines day 2020 (#{valentines.id}, sending): 1 message(s) sent, 1 pending"
    assert_not_includes error.message, "Marry XMAS"
    assert_includes error.message, "UPDATE nuntius_campaigns SET state = 'cancelled' WHERE id IN ('#{valentines.id}');"

    valentines.update_column(:state, "cancelled")
    assert_nil refuse_unsent_campaigns
  end

  private

  def refuse_unsent_campaigns
    ActiveRecord::Migration.suppress_messages { CreateNuntiusEmailLayouts.new.send(:refuse_unsent_campaigns) }
  end
end
