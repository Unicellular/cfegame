class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :effect
      t.belongs_to :turn

      t.timestamps null: false
    end
  end
end
