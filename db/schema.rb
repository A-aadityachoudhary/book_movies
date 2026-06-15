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

ActiveRecord::Schema[8.1].define(version: 2026_06_15_073407) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "showtime_id", null: false
    t.integer "status"
    t.decimal "total_price"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["showtime_id"], name: "index_bookings_on_showtime_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "movies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration"
    t.string "genre"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "screens", force: :cascade do |t|
    t.integer "capacity"
    t.datetime "created_at", null: false
    t.integer "screen_number"
    t.bigint "theater_id", null: false
    t.datetime "updated_at", null: false
    t.index ["theater_id"], name: "index_screens_on_theater_id"
  end

  create_table "seats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "row_name"
    t.bigint "screen_id", null: false
    t.integer "seat_number"
    t.datetime "updated_at", null: false
    t.index ["screen_id"], name: "index_seats_on_screen_id"
  end

  create_table "showtime_seats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "seat_id", null: false
    t.bigint "showtime_id", null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.index ["seat_id"], name: "index_showtime_seats_on_seat_id"
    t.index ["showtime_id"], name: "index_showtime_seats_on_showtime_id"
  end

  create_table "showtimes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "movie_id", null: false
    t.decimal "price"
    t.bigint "screen_id", null: false
    t.datetime "start_time"
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_showtimes_on_movie_id"
    t.index ["screen_id"], name: "index_showtimes_on_screen_id"
  end

  create_table "theaters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.bigint "showtime_seat_id", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_tickets_on_booking_id"
    t.index ["showtime_seat_id"], name: "index_tickets_on_showtime_seat_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "bookings", "showtimes"
  add_foreign_key "bookings", "users"
  add_foreign_key "screens", "theaters"
  add_foreign_key "seats", "screens"
  add_foreign_key "showtime_seats", "seats"
  add_foreign_key "showtime_seats", "showtimes"
  add_foreign_key "showtimes", "movies"
  add_foreign_key "showtimes", "screens"
  add_foreign_key "tickets", "bookings"
  add_foreign_key "tickets", "showtime_seats"
end
