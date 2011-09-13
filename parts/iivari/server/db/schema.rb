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

ActiveRecord::Schema.define(:version => 20110913074947) do

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organisation"
    t.integer  "slide_delay"
    t.string   "theme"
    t.integer  "school_id"
  end

  create_table "displays", :force => true do |t|
    t.boolean  "active",       :default => false
    t.integer  "channel_id"
    t.string   "hostname"
    t.string   "organisation"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "images", :force => true do |t|
    t.string   "key"
    t.string   "content_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "school_admin_groups", :force => true do |t|
    t.integer  "school_id"
    t.integer  "group_id"
    t.string   "organisation"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "slide_timers", :force => true do |t|
    t.datetime "start_datetime"
    t.datetime "end_datetime"
    t.datetime "start_time"
    t.datetime "end_time"
    t.integer  "slide_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "weekday_0",      :default => true
    t.boolean  "weekday_1",      :default => true
    t.boolean  "weekday_2",      :default => true
    t.boolean  "weekday_3",      :default => true
    t.boolean  "weekday_4",      :default => true
    t.boolean  "weekday_5",      :default => true
    t.boolean  "weekday_6",      :default => true
  end

  create_table "slides", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.datetime "created_at"
    t.string   "image"
    t.string   "template"
    t.integer  "channel_id"
    t.integer  "position"
    t.string   "organisation"
    t.boolean  "status",       :default => true
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "persistence_token"
    t.integer  "login_count"
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip"
    t.string   "current_login_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "organisation"
    t.string   "dn"
    t.integer  "puavo_id"
  end

end
