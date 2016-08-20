# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Rule.delete_all
Rule.create(
  [
    { name: "金擊術", description: "／金／金行攻擊，點數＝等級＋４", series: 0, condition: {},
      form: 0, subform: 0, material: { metal: 1, count: 1 }, formula: "sum + 4",
      effect: { target: :last, attack: :point } }
  ]
)
