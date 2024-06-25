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

ActiveRecord::Schema[7.0].define(version: 2016_07_26_140350) do
  create_table "authorizations", force: :cascade do |t|
    t.string "provider"
    t.string "uid"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "cards", force: :cascade do |t|
    t.integer "element", default: 0
    t.integer "level", default: 0
    t.boolean "virtual", default: false
    t.integer "position"
    t.integer "cardholder_id"
    t.string "cardholder_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cardholder_id"], name: "index_cards_on_cardholder_id"
  end

  create_table "decks", force: :cascade do |t|
    t.integer "game_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["game_id"], name: "index_decks_on_game_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "cards_used"
    t.string "effect"
    t.integer "player_id"
    t.integer "target_id"
    t.integer "turn_id"
    t.integer "rule_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["player_id"], name: "index_events_on_player_id"
    t.index ["rule_id"], name: "index_events_on_rule_id"
    t.index ["target_id"], name: "index_events_on_target_id"
    t.index ["turn_id"], name: "index_events_on_turn_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "field", default: 0
    t.integer "status", default: 0
    t.integer "team_amount", default: 2
    t.integer "member_limit", default: 1
    t.integer "turn", default: 0
    t.integer "first", default: 0
    t.boolean "equal_member", default: true
    t.integer "winner"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "players", force: :cascade do |t|
    t.string "star_history"
    t.string "annex"
    t.integer "shield", default: 0
    t.integer "hand_limit", default: 5
    t.integer "sequence"
    t.integer "user_id"
    t.integer "team_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["team_id"], name: "index_players_on_team_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "rules", force: :cascade do |t|
    t.string "name"
    t.string "chinese_name"
    t.string "description"
    t.integer "series"
    t.string "condition"
    t.integer "form"
    t.integer "subform"
    t.integer "target"
    t.string "material"
    t.string "formula"
    t.string "effect"
    t.integer "rule_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["rule_id"], name: "index_rules_on_rule_id"
  end

  create_table "teams", force: :cascade do |t|
    t.integer "life", default: 200
    t.integer "life_limit", default: 200
    t.integer "star", default: 0
    t.string "annex"
    t.integer "maximum", default: 1
    t.integer "game_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["game_id"], name: "index_teams_on_game_id"
  end

  create_table "turns", force: :cascade do |t|
    t.integer "number"
    t.integer "phase", default: 0
    t.integer "game_id"
    t.integer "player_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["game_id"], name: "index_turns_on_game_id"
    t.index ["player_id"], name: "index_turns_on_player_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

end
