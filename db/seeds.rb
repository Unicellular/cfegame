# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'csv'
require 'json'
def reset_pk_sequence(table_name)
  case ActiveRecord::Base.connection.adapter_name
  when 'SQLite'
    update_seq_sql = "update sqlite_sequence set seq = 0 where name = '#{table_name}';"
    ActiveRecord::Base.connection.execute(update_seq_sql)
  when 'PostgreSQL'
    ActiveRecord::Base.connection.reset_pk_sequence!(table_name)
  else
    raise "Task not implemented for this DB adapter"
  end
end
Rule.delete_all
reset_pk_sequence("rules")
CSV.foreach(::Rails.root.join('db', 'basic_rules.csv'), headers: true) do |row|
  data = row.to_hash.map do |key, value|
    if [ "material", "condition", "effect" ].include?( key )
      value = JSON.parse(value)
    end
    [key.to_sym, value]
  end
  Rule.create( Hash[data] )
end
# Rule.create(
#   [
#     { name: "金擊術", description: "／金／金行攻擊，點數＝等級＋４", series: :base, condition: {},
#       form: :attack, subform: :metal, material: { metal: 1, count: 1 }, formula: "sum + 4",
#       effect: { target: -1, attack: :point } },
#     { name: "木擊術", description: "／木／木行攻擊，點數＝等級＋４", series: :base, condition: {},
#       form: :attack, subform: :tree, material: { tree: 1, count: 1 }, formula: "sum + 4",
#       effect: { target: -1, attack: :point } },
#     { name: "水擊術", description: "／水／水行攻擊，點數＝等級＋４", series: :base, condition: {},
#       form: :attack, subform: :water, material: { water: 1, count: 1 }, formula: "sum + 4",
#       effect: { target: -1, attack: :point } },
#     { name: "火擊術", description: "／火／火行攻擊，點數＝等級＋４", series: :base, condition: {},
#       form: :attack, subform: :water, material: { water: 1, count: 1 }, formula: "sum + 4",
#       effect: { target: -1, attack: :point } },
#     { name: "土擊術", description: "／土／土行攻擊，點數＝等級＋４", series: :base, condition: {},
#       form: :attack, subform: :earth, material: { earth: 1, count: 1 }, formula: "sum + 4",
#       effect: { target: -1, attack: :point } },
#     { name: "武器"，description: "／金金／物理攻擊，點數＝等級和×２", series: :base, condition: {},
#       form: :attack, subform: :phyiscal, material: { metal: 2, count: 2 }, formula: "sum * 2",
#       effect: { target: -1, attack: :point } },
#     { name: "防禦"，description: "／木木／被動術式，反制：下家下回合攻擊之傷害無效", series: :base, condition: {},
#       form: :spell, subform: :passive, material: { tree: 2, count: 2 }, formula: "",
#       effect: { target: -1, counter: :attack } },
#     { name: "封印"，description: "／水水／被動術式，反制：下家下回合術式無效", series: :base, condition: {},
#       form: :spell, subform: :passive, material: { water: 2, count: 2 }, formula: "",
#       effect: { target: -1, counter: :spell } },
#     { name: "反震"，description: "／火火／被動術式，反制：下家下回合攻擊之傷害由目標與施展者平分", series: :base, condition: {},
#       form: :spell, subform: :passive, material: { fire: 2, count: 2 }, formula: "",
#       effect: { target: -1, counter: :split } },
#     { name: "幻化"，description: "／土土／主動術式，複製上家上回合施展之基礎規則陣法之類別與效果", series: :base, condition: {},
#       form: :spell, subform: :active, material: { earth: 2, count: 2 }, formula: "",
#       effect: { target: -1, copy: :point } },
#   ]
# )
# head = [ :name, :description, :series, :condition, :form, :subform, :material, :formula, :effect ]
# rules = [
#   [ "金擊術", "／金／金行攻擊，點數＝等級＋４", :base, {}, :attack, :metal, { metal: 1, count: 1 }, "sum + 4", { target: -1, attack: :point } ],
#   [ "金擊術", "／金／金行攻擊，點數＝等級＋４", :base, {}, :attack, :metal, { metal: 1, count: 1 }, "sum + 4", { target: -1, attack: :point } ],
#   [ "金擊術", "／金／金行攻擊，點數＝等級＋４", :base, {}, :attack, :metal, { metal: 1, count: 1 }, "sum + 4", { target: -1, attack: :point } ],
#   [ "金擊術", "／金／金行攻擊，點數＝等級＋４", :base, {}, :attack, :metal, { metal: 1, count: 1 }, "sum + 4", { target: -1, attack: :point } ],
#   [ "金擊術", "／金／金行攻擊，點數＝等級＋４", :base, {}, :attack, :metal, { metal: 1, count: 1 }, "sum + 4", { target: -1, attack: :point } ],
# ]*/
