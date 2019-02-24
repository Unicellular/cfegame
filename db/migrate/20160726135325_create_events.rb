class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :cards_used
      t.string :effect
      t.belongs_to :player
      t.belongs_to :target
      t.belongs_to :turn
      t.belongs_to :rule

      t.timestamps null: false
    end
  end
end
