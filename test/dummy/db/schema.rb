# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_03_22_121338) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "accounts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["list_id"], name: "index_nuntius_campaigns_on_list_id"
  end

  create_table "nuntius_lists", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.integer "subscribers_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nuntius_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "template_id"
    t.uuid "parent_message_id"
    t.string "nuntiable_type"
    t.uuid "nuntiable_id"
    t.integer "refreshes", default: 0
    t.string "status", default: "draft"
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
    t.index ["list_id"], name: "index_nuntius_subscribers_on_list_id"
  end

  create_table "nuntius_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "klass"
    t.string "event"
    t.string "transport"
    t.string "description"
    t.jsonb "metadata", default: {}, null: false
    t.uuid "layout_id"
    t.string "from"
    t.string "to"
    t.string "subject"
    t.text "html"
    t.text "text"
    t.jsonb "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["layout_id"], name: "index_nuntius_templates_on_layout_id"
  end

  add_foreign_key "nuntius_campaigns", "nuntius_lists", column: "list_id"
  add_foreign_key "nuntius_messages", "nuntius_messages", column: "parent_message_id"
  add_foreign_key "nuntius_messages", "nuntius_templates", column: "template_id"
  add_foreign_key "nuntius_subscribers", "nuntius_lists", column: "list_id"
  add_foreign_key "nuntius_templates", "nuntius_templates", column: "layout_id"
end
