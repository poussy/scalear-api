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

ActiveRecord::Schema.define(version: 20171016103808) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "courses", force: :cascade do |t|
    t.integer "user_id"
    t.string "short_name"
    t.string "name"
    t.string "time_zone"
    t.date "start_date"
    t.date "end_date"
    t.date "disable_registration"
    t.text "description"
    t.text "prerequisites"
    t.string "discussion_link", default: ""
    t.string "image_url"
    t.string "unique_identifier"
    t.string "guest_unique_identifier"
    t.boolean "importing", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_unique_identifier"], name: "index_courses_on_guest_unique_identifier", unique: true
    t.index ["unique_identifier"], name: "index_courses_on_unique_identifier", unique: true
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

end
