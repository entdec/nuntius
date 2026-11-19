# frozen_string_literal: true

require "test_helper"

# Saving keeps the user on the record's page, deleting goes back to its list
class AdminSavingTest < ActionDispatch::IntegrationTest
  test "a new list, once saved, is on its own page" do
    post "/nuntius/admin/lists", params: {list: {name: "Spring", slug: "spring"}}

    list = Nuntius::List.find_by!(slug: "spring")
    assert_redirected_to "/nuntius/admin/lists/#{list.id}/edit"
    assert_response :see_other
  end

  test "a subscriber, once saved, stays on its page" do
    list = nuntius_lists(:valentines)

    post "/nuntius/admin/lists/#{list.id}/subscribers", params: {subscriber: {first_name: "Ann", email: "ann@example.com"}}

    subscriber = list.subscribers.find_by!(email: "ann@example.com")
    assert_redirected_to "/nuntius/admin/lists/#{list.id}/subscribers/#{subscriber.id}/edit"

    patch "/nuntius/admin/lists/#{list.id}/subscribers/#{subscriber.id}", params: {subscriber: {last_name: "Smith"}}

    assert_redirected_to "/nuntius/admin/lists/#{list.id}/subscribers/#{subscriber.id}/edit"
    assert_equal "Smith", subscriber.reload.last_name
  end

  test "a deleted template goes back to the templates" do
    template = nuntius_templates(:sms)

    delete "/nuntius/admin/templates/#{template.id}"

    assert_redirected_to "/nuntius/admin/templates"
    assert_not Nuntius::Template.exists?(template.id)
  end

  test "resending a message says so on its page" do
    # Without a transport it isn't delivered again
    message = nuntius_messages(:one_recipient)
    message.update_columns(transport: nil)

    post "/nuntius/admin/messages/#{message.id}/resend"

    assert_redirected_to "/nuntius/admin/messages/#{message.id}"
    assert flash[:notice]
  end
end
