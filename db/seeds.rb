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
[ 'basic_rules.csv', 'star_rules.csv' ].each do | filename |
  CSV.foreach(::Rails.root.join('db', filename), headers: true) do |row|
    data = row.to_hash.map do |key, value|
      if [ "material", "condition", "effect" ].include?( key )
        value = JSON.parse(value)
      end
      [key.to_sym, value]
    end
    Rule.create( Hash[data] )
  end
end
