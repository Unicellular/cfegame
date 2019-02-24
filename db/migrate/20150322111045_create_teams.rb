class CreateTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :teams do |t|
      t.integer :life, default: 200
      t.integer :life_limit, default: 200
      t.integer :star, default: 0
      t.string :annex
      t.integer :maximum, default: 1
      t.belongs_to :game

      t.timestamps null: false
    end
  end
end
