class CreateCards < ActiveRecord::Migration[5.2]
  def change
    create_table :cards do |t|
      t.integer :element, default: 0
      t.integer :level, default: 0
      t.boolean :virtual, default: false
      t.integer :position
      t.belongs_to :cardholder
      t.string :cardholder_type

      t.timestamps null: false
    end
  end
end
