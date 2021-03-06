class CreateGames < ActiveRecord::Migration[5.2]
  def change
    create_table :games do |t|
      t.integer :field, default: 0
      t.integer :status, default: 0
      t.integer :team_amount, default: 2
      t.integer :member_limit, default: 1
      t.integer :turn, default: 0
      t.integer :first, default: 0
      t.boolean :equal_member, default: true
      t.integer :winner

      t.timestamps null: false
    end
  end
end
