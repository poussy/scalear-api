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

ActiveRecord::Schema.define(version: 20171016164453) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "announcements", force: :cascade do |t|
    t.string "name"
    t.integer "course_id"
    t.integer "user_id"
    t.datetime "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "updated_at"], name: "index_announcements_on_course_id_and_updated_at"
    t.index ["course_id"], name: "index_announcements_on_course_id"
    t.index ["updated_at"], name: "index_announcements_on_updated_at"
    t.index ["user_id"], name: "index_announcements_on_user_id"
  end

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
    t.integer "parent_id"
    t.index ["guest_unique_identifier"], name: "index_courses_on_guest_unique_identifier", unique: true
    t.index ["unique_identifier"], name: "index_courses_on_unique_identifier", unique: true
    t.index ["user_id"], name: "index_courses_on_user_id"
  end

  create_table "custom_links", force: :cascade do |t|
    t.string "name"
    t.integer "group_id"
    t.integer "course_id"
    t.integer "position"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "updated_at"], name: "index_custom_links_on_course_id_and_updated_at"
    t.index ["course_id"], name: "index_custom_links_on_course_id"
    t.index ["group_id"], name: "index_custom_links_on_group_id"
    t.index ["updated_at"], name: "index_custom_links_on_updated_at"
  end

  create_table "enrollments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.boolean "email_due_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "course_id"
    t.date "appearance_time"
    t.date "due_date"
    t.boolean "inorder"
    t.boolean "required"
    t.integer "position"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.index ["course_id", "updated_at"], name: "index_groups_on_course_id_and_updated_at"
    t.index ["course_id"], name: "index_groups_on_course_id"
    t.index ["updated_at"], name: "index_groups_on_updated_at"
  end

  create_table "lectures", force: :cascade do |t|
    t.string "name"
    t.float "start_time"
    t.float "end_time"
    t.float "duration"
    t.integer "group_id"
    t.integer "course_id"
    t.boolean "appearance_time_module"
    t.datetime "appearance_time"
    t.boolean "due_date_module"
    t.datetime "due_date"
    t.string "slides"
    t.integer "position"
    t.string "aspect_ratio", default: "widescreen"
    t.boolean "required", default: true
    t.boolean "inordered", default: true
    t.boolean "required_module", default: true
    t.boolean "inordered_module", default: true
    t.string "type", default: "normal"
    t.text "description"
    t.string "url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.index ["course_id", "updated_at"], name: "index_lectures_on_course_id_and_updated_at"
    t.index ["course_id"], name: "index_lectures_on_course_id"
    t.index ["group_id"], name: "index_lectures_on_group_id"
    t.index ["updated_at"], name: "index_lectures_on_updated_at"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "name"
    t.integer "retries"
    t.integer "group_id"
    t.integer "course_id"
    t.boolean "appearance_time_module"
    t.datetime "appearance_time"
    t.boolean "due_date_module"
    t.datetime "due_date"
    t.integer "position"
    t.boolean "required", default: true
    t.boolean "inordered", default: true
    t.boolean "required_module", default: true
    t.boolean "inordered_module", default: true
    t.boolean "visible", default: false
    t.string "type"
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "parent_id"
    t.index ["course_id", "updated_at"], name: "index_quizzes_on_course_id_and_updated_at"
    t.index ["course_id"], name: "index_quizzes_on_course_id"
    t.index ["group_id"], name: "index_quizzes_on_group_id"
    t.index ["updated_at"], name: "index_quizzes_on_updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "teacher_enrollments", force: :cascade do |t|
    t.integer "user_id"
    t.integer "course_id"
    t.string "role"
    t.boolean "email_discussion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_teacher_enrollments_on_course_id"
    t.index ["user_id"], name: "index_teacher_enrollments_on_user_id"
  end

  create_table "users_roles", force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
