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

ActiveRecord::Schema.define(version: 2020_09_09_084353) do

  create_table "contracts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "shop_id", null: false
    t.float "hourly_wage", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at"
    t.index ["shop_id"], name: "index_contracts_on_shop_id"
    t.index ["user_id"], name: "index_contracts_on_user_id"
  end

  create_table "shifts", force: :cascade do |t|
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "user_id"
    t.integer "shop_id", null: false
    t.integer "category", default: 0, null: false
    t.index ["shop_id"], name: "index_shifts_on_shop_id"
    t.index ["user_id"], name: "index_shifts_on_user_id"
  end

  create_table "shops", force: :cascade do |t|
    t.string "name", null: false
    t.index ["name"], name: "index_shops_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "firstname", null: false
    t.string "lastname", null: false
    t.string "email"
    t.string "password_digest", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "contracts", "shops"
  add_foreign_key "contracts", "users"
  add_foreign_key "shifts", "shops"
  add_foreign_key "shifts", "users"
end
