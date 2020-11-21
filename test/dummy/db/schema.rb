# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_21_185718) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "nuntius_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_attachments_messages", id: false, force: :cascade do |t|
    t.uuid "message_id"
    t.uuid "attachment_id"
    t.index ["attachment_id"], name: "index_nuntius_attachments_messages_on_attachment_id"
    t.index ["message_id"], name: "index_nuntius_attachments_messages_on_message_id"
  end

  create_table "nuntius_campaigns", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "transport", default: "mail"
    t.uuid "list_id"
    t.string "from"
    t.string "subject"
    t.text "text"
    t.text "html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.uuid "layout_id"
    t.string "state"
    t.index ["layout_id"], name: "index_nuntius_campaigns_on_layout_id"
    t.index ["list_id"], name: "index_nuntius_campaigns_on_list_id"
  end

  create_table "nuntius_inbound_mails", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "state"
    t.string "message_id"
    t.string "digest"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "nuntius_layouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.text "data"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_lists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "subscribers_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "metadata", default: {}, null: false
  end

  create_table "nuntius_locales", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key"
    t.jsonb "data"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "template_id"
    t.uuid "parent_message_id"
    t.string "nuntiable_type"
    t.uuid "nuntiable_id"
    t.integer "refreshes", default: 0
    t.string "status", default: "pending"
    t.string "transport"
    t.string "provider"
    t.string "provider_id"
    t.string "request_id"
    t.string "from"
    t.string "to"
    t.string "subject"
    t.text "html"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "campaign_id"
    t.jsonb "payload"
    t.jsonb "metadata", default: {}
    t.index ["campaign_id"], name: "index_nuntius_messages_on_campaign_id"
    t.index ["nuntiable_type", "nuntiable_id"], name: "index_nuntius_messages_on_nuntiable_type_and_nuntiable_id"
    t.index ["parent_message_id"], name: "index_nuntius_messages_on_parent_message_id"
    t.index ["template_id"], name: "index_nuntius_messages_on_template_id"
  end

  create_table "nuntius_subscribers", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "list_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone_number"
    t.string "tags"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nuntiable_type"
    t.uuid "nuntiable_id"
    t.index ["list_id"], name: "index_nuntius_subscribers_on_list_id"
    t.index ["nuntiable_type", "nuntiable_id"], name: "index_nuntius_subscribers_on_nuntiable_type_and_nuntiable_id"
  end

  create_table "nuntius_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "klass"
    t.string "event"
    t.string "transport"
    t.string "description"
    t.jsonb "metadata", default: {}, null: false
    t.string "from"
    t.string "to"
    t.string "subject"
    t.text "html"
    t.text "text"
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "layout_id"
    t.boolean "enabled", default: true
    t.string "interval"
    t.index ["layout_id"], name: "index_nuntius_templates_on_layout_id"
  end

  create_table "sti_bases", force: :cascade do |t|
    t.string "type"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "nuntius_attachments_messages", "nuntius_attachments", column: "attachment_id"
  add_foreign_key "nuntius_attachments_messages", "nuntius_messages", column: "message_id"
  add_foreign_key "nuntius_campaigns", "nuntius_layouts", column: "layout_id"
  add_foreign_key "nuntius_campaigns", "nuntius_lists", column: "list_id"
  add_foreign_key "nuntius_messages", "nuntius_campaigns", column: "campaign_id"
  add_foreign_key "nuntius_messages", "nuntius_messages", column: "parent_message_id"
  add_foreign_key "nuntius_messages", "nuntius_templates", column: "template_id"
  add_foreign_key "nuntius_subscribers", "nuntius_lists", column: "list_id"
  add_foreign_key "nuntius_templates", "nuntius_layouts", column: "layout_id"
end
