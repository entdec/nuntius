# frozen_string_literal: true

require "test_helper"

module Nuntius
  class PushProvidersTest < ActiveSupport::TestCase
    APNS_TOKEN = "a" * 64

    test "APNs handles APNs device tokens, and Firebase the other tokens" do
      assert Nuntius::ApnoticPushProvider.handles?(APNS_TOKEN)
      refute Nuntius::ApnoticPushProvider.handles?("fcm-token:APA91b" + "x" * 140)
      refute Nuntius::FirebasePushProvider.handles?(APNS_TOKEN)
      assert Nuntius::FirebasePushProvider.handles?("fcm-token:APA91b" + "x" * 140)
    end
  end
end
