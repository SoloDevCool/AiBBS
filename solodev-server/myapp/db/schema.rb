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

ActiveRecord::Schema[8.1].define(version: 2026_04_06_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocked_id", null: false
    t.bigint "blocker_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
  end

  create_table "chat_groups", force: :cascade do |t|
    t.string "category"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.integer "members_count", default: 0, null: false
    t.string "name", null: false
    t.integer "sort_order", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "check_ins", force: :cascade do |t|
    t.date "checked_on", null: false
    t.datetime "created_at", null: false
    t.integer "points_earned", default: 10, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "checked_on"], name: "index_check_ins_on_user_id_and_checked_on", unique: true
    t.index ["user_id"], name: "index_check_ins_on_user_id"
  end

  create_table "comment_cools", force: :cascade do |t|
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id"], name: "index_comment_cools_on_comment_id"
    t.index ["user_id", "comment_id"], name: "index_comment_cools_on_user_id_and_comment_id", unique: true
    t.index ["user_id"], name: "index_comment_cools_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.boolean "login_only", default: false, null: false
    t.bigint "parent_id"
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["topic_id"], name: "index_comments_on_topic_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "cools", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["topic_id"], name: "index_cools_on_topic_id"
    t.index ["user_id", "topic_id"], name: "index_cools_on_user_id_and_topic_id", unique: true
    t.index ["user_id"], name: "index_cools_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followed_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "friend_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "is_active", default: true
    t.string "logo"
    t.string "name", null: false
    t.integer "sort_order", default: 0
    t.datetime "updated_at", null: false
    t.string "url", null: false
  end

  create_table "images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "invitation_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "expires_at"
    t.integer "max_uses", default: 1, null: false
    t.datetime "updated_at", null: false
    t.integer "used_count", default: 0, null: false
    t.index ["code"], name: "index_invitation_codes_on_code", unique: true
    t.index ["created_by_id"], name: "index_invitation_codes_on_created_by_id"
  end

  create_table "jwt_denylist", id: false, force: :cascade do |t|
    t.datetime "exp", null: false
    t.string "jti", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "mentions", force: :cascade do |t|
    t.bigint "comment_id"
    t.datetime "created_at", null: false
    t.bigint "topic_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id", "user_id"], name: "index_mentions_on_comment_id_and_user_id"
    t.index ["comment_id"], name: "index_mentions_on_comment_id"
    t.index ["topic_id", "user_id"], name: "index_mentions_on_topic_id_and_user_id"
    t.index ["topic_id"], name: "index_mentions_on_topic_id"
    t.index ["user_id"], name: "index_mentions_on_user_id"
  end

  create_table "node_follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "node_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["node_id"], name: "index_node_follows_on_node_id"
    t.index ["user_id", "node_id"], name: "index_node_follows_on_user_id_and_node_id", unique: true
    t.index ["user_id"], name: "index_node_follows_on_user_id"
  end

  create_table "nodes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "kind", default: "interest", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.integer "sort_order", default: 0, null: false
    t.integer "topics_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_nodes_on_position"
    t.index ["slug"], name: "index_nodes_on_slug", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.string "notify_type", null: false
    t.boolean "read", default: false, null: false
    t.bigint "user_id", null: false
    t.index ["actor_id", "notify_type", "notifiable_id", "notifiable_type"], name: "index_notifications_unique", unique: true
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
  end

  create_table "poll_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id", null: false
    t.integer "sort_order", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0, null: false
    t.index ["poll_id"], name: "index_poll_options_on_poll_id"
  end

  create_table "polls", force: :cascade do |t|
    t.boolean "closed", default: false, null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_polls_on_topic_id", unique: true
    t.index ["topic_id"], name: "index_polls_on_topic_id_unique", unique: true
  end

  create_table "site_appearances", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "logo_display_mode", default: "text", null: false
    t.datetime "updated_at", null: false
  end

  create_table "site_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.text "value"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "tips", force: :cascade do |t|
    t.integer "amount", null: false
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.bigint "from_user_id", null: false
    t.bigint "to_user_id", null: false
    t.bigint "topic_id", null: false
    t.datetime "updated_at", null: false
    t.index ["comment_id"], name: "index_tips_on_comment_id"
    t.index ["from_user_id"], name: "index_tips_on_from_user_id"
    t.index ["to_user_id"], name: "index_tips_on_to_user_id"
    t.index ["topic_id"], name: "index_tips_on_topic_id"
  end

  create_table "topics", force: :cascade do |t|
    t.integer "comments_count", default: 0, null: false
    t.text "content", null: false
    t.integer "cools_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.boolean "is_repost", default: false, null: false
    t.datetime "last_reply_at"
    t.integer "last_reply_user_id"
    t.bigint "node_id", null: false
    t.boolean "pinned", default: false, null: false
    t.datetime "pinned_at"
    t.string "slug"
    t.string "source_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["node_id", "updated_at"], name: "index_topics_on_node_id_and_updated_at"
    t.index ["node_id"], name: "index_topics_on_node_id"
    t.index ["pinned"], name: "index_topics_on_pinned", where: "(pinned = true)"
    t.index ["slug"], name: "index_topics_on_slug"
    t.index ["user_id", "created_at"], name: "index_topics_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_topics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.text "avatar_data"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.bigint "invitation_code_id"
    t.boolean "is_operational", default: false, null: false
    t.string "plaintext_password"
    t.integer "points", default: 0, null: false
    t.boolean "profile_public", default: true, null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.string "uid"
    t.integer "unread_notifications_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_code_id"], name: "index_users_on_invitation_code_id"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["poll_option_id", "user_id"], name: "index_votes_on_poll_option_id_and_user_id", unique: true
    t.index ["poll_option_id"], name: "index_votes_on_poll_option_id"
    t.index ["user_id", "poll_option_id"], name: "index_votes_on_user_id_and_poll_option_id", unique: true
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "check_ins", "users"
  add_foreign_key "comment_cools", "comments"
  add_foreign_key "comment_cools", "users"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "topics"
  add_foreign_key "comments", "users"
  add_foreign_key "cools", "topics"
  add_foreign_key "cools", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "images", "users"
  add_foreign_key "invitation_codes", "users", column: "created_by_id"
  add_foreign_key "mentions", "comments"
  add_foreign_key "mentions", "topics"
  add_foreign_key "mentions", "users"
  add_foreign_key "node_follows", "nodes"
  add_foreign_key "node_follows", "users"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "polls", "topics", on_delete: :cascade
  add_foreign_key "tips", "comments"
  add_foreign_key "tips", "topics"
  add_foreign_key "tips", "users", column: "from_user_id"
  add_foreign_key "tips", "users", column: "to_user_id"
  add_foreign_key "topics", "nodes"
  add_foreign_key "topics", "users"
  add_foreign_key "users", "invitation_codes"
  add_foreign_key "votes", "poll_options"
  add_foreign_key "votes", "users"
end
