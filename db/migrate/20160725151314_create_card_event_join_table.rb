class CreateCardEventJoinTable < ActiveRecord::Migration
  def change
    create_join_table :cards, :events do |t|
      t.index [:card_id, :event_id]
      t.index [:event_id, :card_id]
    end
  end
end
