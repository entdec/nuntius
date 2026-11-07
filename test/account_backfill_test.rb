# frozen_string_literal: true

require "test_helper"

class AccountBackfillTest < ActiveSupport::TestCase
  setup do
    @other = Account.create!(name: "other")
    # As before the migration: no account yet. The test's transaction undoes this.
    Nuntius::AccountBackfill::TABLES.each { |table| ActiveRecord::Base.connection.change_column_null(table, :account_id, true) }
  end

  test "takes the account from metadata, and leaves the rest of it" do
    template = nuntius_templates(:email)
    template.update_columns(account_id: nil, metadata: {"account_id" => @other.id, "global" => "true", "logo_url" => "logo.png"})

    Nuntius::AccountBackfill.new.call

    template.reload
    assert_equal @other, template.account
    assert template.global
    assert_equal({"logo_url" => "logo.png"}, template.metadata)
  end

  test "reads global as a string or a boolean" do
    nuntius_templates(:email).update_columns(account_id: nil, metadata: {"account_id" => @other.id, "global" => true})
    nuntius_templates(:sms).update_columns(account_id: nil, metadata: {"account_id" => @other.id, "global" => "false"})

    Nuntius::AccountBackfill.new.call

    assert nuntius_templates(:email).reload.global
    assert_not nuntius_templates(:sms).reload.global
  end

  test "a message without an account in its metadata gets its template's or campaign's" do
    template_message = Nuntius::Message.create!(transport: "mail", template: nuntius_templates(:email))
    campaign_message = Nuntius::Message.create!(transport: "mail", campaign: nuntius_campaigns(:xmas))
    nuntius_campaigns(:xmas).update_columns(account_id: @other.id)
    Nuntius::Message.where(id: [template_message, campaign_message]).update_all(account_id: nil)

    Nuntius::AccountBackfill.new.call

    assert_equal accounts(:one), template_message.reload.account
    assert_equal @other, campaign_message.reload.account
  end

  test "records with an unknown account or none are left, with their metadata, unless a fallback is given" do
    campaign = nuntius_campaigns(:valentines_day)
    campaign.update_columns(account_id: nil, metadata: {"account_id" => SecureRandom.uuid})
    nuntius_lists(:helpers).update_columns(account_id: nil)

    backfill = Nuntius::AccountBackfill.new
    backfill.call

    assert_equal({"nuntius_campaigns" => 1, "nuntius_lists" => 1}, backfill.unassigned)
    assert campaign.reload.metadata["account_id"]

    Nuntius::AccountBackfill.new(fallback_account_id: @other.id).call

    assert_equal @other, campaign.reload.account
    assert_equal @other, nuntius_lists(:helpers).reload.account
  end

  test "updates in batches" do
    stub_const(Nuntius::AccountBackfill, :BATCH_SIZE, 2) do
      Nuntius::Template.update_all(account_id: nil, metadata: {"account_id" => @other.id})

      Nuntius::AccountBackfill.new.call

      assert_equal Nuntius::Template.count, Nuntius::Template.where(account_id: @other.id).count
      assert_equal 0, Nuntius::Template.where("metadata ? 'account_id'").count
    end
  end

  private

  def stub_const(mod, name, value)
    original = mod.const_get(name)
    mod.send(:remove_const, name)
    mod.const_set(name, value)
    yield
  ensure
    mod.send(:remove_const, name)
    mod.const_set(name, original)
  end
end
