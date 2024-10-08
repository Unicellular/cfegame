class CreateTurns < ActiveRecord::Migration[5.2]
  def change
    create_table :turns do |t|
      t.integer :number
      t.integer :phase, default: 0
      t.belongs_to :game
      t.belongs_to :player

      t.timestamps null: false
    end
  end
end
