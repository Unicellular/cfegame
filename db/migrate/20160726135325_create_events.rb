class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :cards_used
      t.string :effect
      t.belongs_to :player
      t.belongs_to :target
      t.belongs_to :turn

      t.timestamps null: false
    end
  end
end
