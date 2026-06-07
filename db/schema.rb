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

ActiveRecord::Schema[8.1].define(version: 2026_06_07_001243) do
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

  create_table "application_settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "hardcover_api_token"
    t.boolean "singleton_guard", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["singleton_guard"], name: "index_application_settings_on_singleton_guard", unique: true
  end

  create_table "authors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_authors_on_name", unique: true
  end

  create_table "book_files", force: :cascade do |t|
    t.integer "book_id", null: false
    t.datetime "created_at", null: false
    t.string "format", null: false
    t.datetime "mtime", null: false
    t.string "relative_path", null: false
    t.integer "size_bytes", null: false
    t.string "status", default: "present", null: false
    t.datetime "updated_at", null: false
    t.index ["book_id", "format", "relative_path"], name: "index_book_files_on_book_id_and_format_and_relative_path", unique: true
    t.index ["book_id"], name: "index_book_files_on_book_id"
    t.index ["relative_path"], name: "index_book_files_on_relative_path"
    t.index ["status"], name: "index_book_files_on_status"
  end

  create_table "books", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.integer "library_id", null: false
    t.integer "series_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_books_on_author_id"
    t.index ["library_id", "author_id", "series_id", "title"], name: "idx_on_library_id_author_id_series_id_title_071ab040c9", unique: true
    t.index ["library_id"], name: "index_books_on_library_id"
    t.index ["series_id"], name: "index_books_on_series_id"
  end

  create_table "libraries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "root_path", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_libraries_on_name", unique: true
    t.index ["root_path"], name: "index_libraries_on_root_path", unique: true
  end

  create_table "scan_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_count", default: 0, null: false
    t.integer "error_count", default: 0, null: false
    t.datetime "finished_at"
    t.integer "found_count", default: 0, null: false
    t.text "last_error"
    t.integer "library_id", null: false
    t.integer "missing_count", default: 0, null: false
    t.datetime "started_at"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_count", default: 0, null: false
    t.index ["library_id"], name: "index_scan_runs_on_library_id"
    t.index ["status"], name: "index_scan_runs_on_status"
  end

  create_table "series", force: :cascade do |t|
    t.integer "author_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id", "name"], name: "index_series_on_author_id_and_name", unique: true
    t.index ["author_id"], name: "index_series_on_author_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.integer "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "book_files", "books"
  add_foreign_key "books", "authors"
  add_foreign_key "books", "libraries"
  add_foreign_key "books", "series"
  add_foreign_key "scan_runs", "libraries"
  add_foreign_key "series", "authors"
  add_foreign_key "sessions", "users"
end
