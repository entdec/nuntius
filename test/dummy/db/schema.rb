# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_10_122500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.uuid "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "nuntius_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_attachments_messages", id: false, force: :cascade do |t|
    t.uuid "attachment_id"
    t.uuid "message_id"
    t.index ["attachment_id"], name: "index_nuntius_attachments_messages_on_attachment_id"
    t.index ["message_id"], name: "index_nuntius_attachments_messages_on_message_id"
  end

  create_table "nuntius_campaigns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from"
    t.text "html"
    t.uuid "layout_id"
    t.boolean "link_tracking", default: false
    t.uuid "list_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.boolean "open_tracking", default: false
    t.string "state"
    t.string "subject"
    t.text "text"
    t.string "transport", default: "mail"
    t.datetime "updated_at", null: false
    t.index ["layout_id"], name: "index_nuntius_campaigns_on_layout_id"
    t.index ["list_id"], name: "index_nuntius_campaigns_on_list_id"
  end

  create_table "nuntius_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "transition_attribute"
    t.string "transition_event"
    t.string "transition_from"
    t.string "transition_to"
    t.uuid "transitionable_id"
    t.string "transitionable_type"
    t.datetime "updated_at", null: false
    t.index ["transitionable_type", "transitionable_id", "transition_event"], name: "index_nuntius_events_on_type_id_event"
  end

  create_table "nuntius_inbound_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "cc"
    t.datetime "created_at", null: false
    t.string "digest"
    t.string "from"
    t.text "html"
    t.jsonb "metadata"
    t.jsonb "payload"
    t.string "provider"
    t.string "provider_id"
    t.string "status", default: "pending"
    t.string "subject"
    t.text "text"
    t.string "to"
    t.string "transport"
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_layouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "data"
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_lists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "allow_unsubscribe", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.string "name"
    t.string "slug"
    t.integer "subscribers_count"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_nuntius_lists_on_slug", unique: true
  end

  create_table "nuntius_locales", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.string "key"
    t.jsonb "metadata"
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_message_trackings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "count", default: 0
    t.datetime "created_at", null: false
    t.uuid "message_id"
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["message_id"], name: "index_nuntius_message_trackings_on_message_id"
  end

  create_table "nuntius_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "campaign_id"
    t.integer "click_count", default: 0
    t.datetime "clicked_at"
    t.datetime "created_at", null: false
    t.string "from"
    t.text "html"
    t.datetime "last_sent_at", precision: nil
    t.jsonb "metadata", default: {}
    t.uuid "nuntiable_id"
    t.string "nuntiable_type"
    t.integer "open_count", default: 0
    t.datetime "opened_at"
    t.uuid "parent_message_id"
    t.jsonb "payload"
    t.string "provider"
    t.string "provider_id"
    t.integer "refreshes", default: 0
    t.string "request_id"
    t.string "status", default: "pending"
    t.string "subject"
    t.uuid "template_id"
    t.text "text"
    t.string "to"
    t.string "transport"
    t.datetime "updated_at", null: false
    t.index ["campaign_id"], name: "index_nuntius_messages_on_campaign_id"
    t.index ["nuntiable_type", "nuntiable_id"], name: "index_nuntius_messages_on_nuntiable_type_and_nuntiable_id"
    t.index ["parent_message_id"], name: "index_nuntius_messages_on_parent_message_id"
    t.index ["template_id"], name: "index_nuntius_messages_on_template_id"
  end

  create_table "nuntius_subscribers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.uuid "list_id"
    t.uuid "nuntiable_id"
    t.string "nuntiable_type"
    t.string "phone_number"
    t.string "tags"
    t.datetime "unsubscribed_at", precision: nil
    t.datetime "updated_at", null: false
    t.index ["list_id"], name: "index_nuntius_subscribers_on_list_id"
    t.index ["nuntiable_type", "nuntiable_id"], name: "index_nuntius_subscribers_on_nuntiable_type_and_nuntiable_id"
  end

  create_table "nuntius_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "enabled", default: true
    t.string "event"
    t.string "from"
    t.text "html"
    t.string "interval"
    t.string "klass"
    t.uuid "layout_id"
    t.boolean "link_tracking", default: false
    t.jsonb "metadata", default: {}, null: false
    t.boolean "open_tracking", default: false
    t.text "payload"
    t.string "subject"
    t.text "text"
    t.string "to"
    t.string "transport"
    t.datetime "updated_at", null: false
    t.index ["layout_id"], name: "index_nuntius_templates_on_layout_id"
  end

  create_table "reports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "state"
    t.datetime "updated_at", null: false
  end

  create_table "sti_bases", force: :cascade do |t|
    t.string "type"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "name"
    t.string "state"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "nuntius_attachments_messages", "nuntius_attachments", column: "attachment_id"
  add_foreign_key "nuntius_attachments_messages", "nuntius_messages", column: "message_id"
  add_foreign_key "nuntius_campaigns", "nuntius_layouts", column: "layout_id"
  add_foreign_key "nuntius_campaigns", "nuntius_lists", column: "list_id"
  add_foreign_key "nuntius_message_trackings", "nuntius_messages", column: "message_id"
  add_foreign_key "nuntius_messages", "nuntius_campaigns", column: "campaign_id"
  add_foreign_key "nuntius_messages", "nuntius_messages", column: "parent_message_id"
  add_foreign_key "nuntius_messages", "nuntius_templates", column: "template_id"
  add_foreign_key "nuntius_subscribers", "nuntius_lists", column: "list_id"
  add_foreign_key "nuntius_templates", "nuntius_layouts", column: "layout_id"
end
