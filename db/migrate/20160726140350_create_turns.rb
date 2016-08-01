class CreateTurns < ActiveRecord::Migration
  def change
    create_table :turns do |t|
      t.integer :number
      t.belongs_to  :game

      t.timestamps null: false
    end
  end
end
