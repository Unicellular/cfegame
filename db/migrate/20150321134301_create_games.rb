class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :winner
      t.string :field
      t.integer :status, default: 0
      t.integer :team_amount, default: 2
      t.integer :member_limit, default: 1
      t.integer :turn, default: 0
      t.integer :first, default: 0
      t.boolean :equal_member, default: true

      t.timestamps null: false
    end
  end
end
