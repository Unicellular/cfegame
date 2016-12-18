class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :star_history
      t.string :sustained
      t.integer :shell, default: 0
      t.integer :hand_limit, default: 5
      t.integer :sequence
      t.belongs_to :user
      t.belongs_to :team

      t.timestamps null: false
    end
  end
end
