# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
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
Rule.create(
  [
    { name: "金擊術", description: "／金／金行攻擊，點數＝等級＋４", series: 0, condition: {},
      form: 0, subform: 0, material: { metal: 1, count: 1 }, formula: "sum + 4",
      effect: { target: :last, attack: :point } }
  ]
)
