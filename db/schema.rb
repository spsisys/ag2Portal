# encoding: UTF-8
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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130328200830) do

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "fiscal_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "street_type_id"
    t.string   "street_name"
    t.string   "street_number"
    t.string   "building"
    t.integer  "floor"
    t.string   "floor_office"
    t.integer  "zipcode_id"
    t.integer  "town_id"
    t.integer  "province_id"
  end

  add_index "companies", ["province_id"], :name => "index_companies_on_province_id"
  add_index "companies", ["street_type_id"], :name => "index_companies_on_street_type_id"
  add_index "companies", ["town_id"], :name => "index_companies_on_town_id"
  add_index "companies", ["zipcode_id"], :name => "index_companies_on_zipcode_id"

  create_table "offices", :force => true do |t|
    t.string   "name"
    t.integer  "company_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "office_code"
  end

  add_index "offices", ["company_id"], :name => "index_offices_on_company_id"
  add_index "offices", ["office_code"], :name => "index_offices_on_office_code"

  create_table "provinces", :force => true do |t|
    t.string   "name"
    t.string   "ine_cpro"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "provinces", ["ine_cpro"], :name => "index_provinces_on_ine_cpro"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "street_types", :force => true do |t|
    t.string   "street_type_code"
    t.string   "street_type_description"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  add_index "street_types", ["street_type_code"], :name => "index_street_types_on_street_type_code"

  create_table "towns", :force => true do |t|
    t.string   "name"
    t.string   "ine_cmun"
    t.string   "ine_dc"
    t.integer  "province_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "towns", ["ine_cmun"], :name => "index_towns_on_ine_cmun"
  add_index "towns", ["province_id"], :name => "index_towns_on_province_id"

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "name",                   :default => "", :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "users_roles", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"

  create_table "zipcodes", :force => true do |t|
    t.string   "zipcode"
    t.integer  "town_id"
    t.integer  "province_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "zipcodes", ["province_id"], :name => "index_zipcodes_on_province_id"
  add_index "zipcodes", ["town_id"], :name => "index_zipcodes_on_town_id"
  add_index "zipcodes", ["zipcode"], :name => "index_zipcodes_on_zipcode"

end
