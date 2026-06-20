# frozen_string_literal: true

require "test_helper"

module Nuntius
  class ImportSubscribersJobTest < ActiveSupport::TestCase
    test "imports subscribers from CSV" do
      list = Nuntius::List.create!(name: "Test List", slug: "test-list")
      blob = create_blob("first_name,last_name,email,nationality\nBob ,Smith,bob@example.com, UK")
      Nuntius::ImportSubscribersJob.perform_now(list, blob, nil)
      assert_equal "Bob", list.subscribers.first.first_name
      assert_equal "Smith", list.subscribers.first.last_name
      assert_equal "bob@example.com", list.subscribers.first.email
      assert_equal "UK", list.subscribers.first.metadata["nationality"]
    end

    test "imports subscribers from CSV with semicolons" do
      list = Nuntius::List.create!(name: "Test List", slug: "test-list")
      blob = create_blob("first_name;last_name;email;nationality\nBob ;Smith;bob@example.com; UK")
      Nuntius::ImportSubscribersJob.perform_now(list, blob, nil)
      assert_equal "Bob", list.subscribers.first.first_name
      assert_equal "Smith", list.subscribers.first.last_name
      assert_equal "bob@example.com", list.subscribers.first.email
      assert_equal "UK", list.subscribers.first.metadata["nationality"]
    end

    test "updates subscribers from CSV with semicolons" do
      list = Nuntius::List.create!(name: "Test List", slug: "test-list")
      john = list.subscribers.create(first_name: "John", last_name: "Doe", email: "john@example.com")

      blob = create_blob("id;last_name\n#{john.id};Smith;")
      Nuntius::ImportSubscribersJob.perform_now(list, blob, nil)
      assert_equal "Smith", list.subscribers.first.last_name
    end

    def create_blob(content)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(content),
        filename: "subscribers.csv",
        content_type: "text/csv"
      )
    end
  end
end
