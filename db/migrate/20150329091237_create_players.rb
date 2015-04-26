class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.boolean :metal_summoned, default: false
      t.boolean :wood_summoned, default: false
      t.boolean :water_summoned, default: false
      t.boolean :fire_summoned, default: false
      t.boolean :earth_summoned, default: false
      t.integer :shell, default: 0
      t.integer :hand_limit, default: 5
      t.belongs_to :user
      t.belongs_to :team

      t.timestamps null: false
    end
  end
end
