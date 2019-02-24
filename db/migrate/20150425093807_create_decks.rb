class CreateDecks < ActiveRecord::Migration[5.2]
  def change
    create_table :decks do |t|
      t.belongs_to :game

      t.timestamps null: false
    end
  end
end
