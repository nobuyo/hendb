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

ActiveRecord::Schema.define(version: 20170203082018) do

  create_table "aspire_univs", force: :cascade do |t|
    t.integer "user_id"
    t.integer "univ_id"
    t.index ["univ_id"], name: "index_aspire_univs_on_univ_id"
    t.index ["user_id"], name: "index_aspire_univs_on_user_id"
  end

  create_table "exams", force: :cascade do |t|
    t.integer "univ_id"
    t.integer "subject"
    t.index ["univ_id"], name: "index_exams_on_univ_id"
  end

  create_table "univs", force: :cascade do |t|
    t.string   "name"
    t.string   "pref"
    t.integer  "deviation_value"
    t.date     "exam_date"
    t.date     "result_date"
    t.date     "affirmation_date"
    t.integer  "admit_units"
    t.text     "remark"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "dept"
    t.string   "url"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "password_hash"
    t.string   "password_salt"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

end
