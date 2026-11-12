# frozen_string_literal: true

require "test_helper"
require Nuntius::Engine.root.join("db/migrate/20261107100000_create_nuntius_email_layouts")
require Nuntius::Engine.root.join("db/migrate/20261112100000_move_nuntius_lmtp_to_mail")

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

  test "the LMTP migration moves templates, campaigns and messages to mail, with their translations" do
    template = nuntius_templates(:two_recipients_with_translations)
    template.update_column(:transport, "lmtp")
    locale = nuntius_locales(:nl)
    data = locale.data.deep_dup
    data["nl"]["account"]["translationtest"]["lmtp"] = data["nl"]["account"]["translationtest"].delete("mail")
    locale.update_column(:data, data)
    campaign = nuntius_campaigns(:xmas)
    campaign.update_column(:transport, "lmtp")
    message = Nuntius::Message.create!(transport: "lmtp", provider: "lmtp", to: "user@example.com@mx.internal:24")

    ActiveRecord::Migration.suppress_messages { MoveNuntiusLmtpToMail.new.up }

    assert_equal "mail", template.reload.transport
    assert_equal "Hoi", locale.reload.data.dig("nl", "account", "translationtest", "mail", "greeting")
    assert_nil locale.data.dig("nl", "account", "translationtest", "lmtp")
    assert_equal "mail", campaign.reload.transport
    assert_equal "mail", message.reload.transport
    assert_equal Nuntius::LmtpMailProvider, Nuntius::BaseProvider.class_from_name(message.provider, message.transport)
  end

  private

  def refuse_unsent_campaigns
    ActiveRecord::Migration.suppress_messages { CreateNuntiusEmailLayouts.new.send(:refuse_unsent_campaigns) }
  end
end
