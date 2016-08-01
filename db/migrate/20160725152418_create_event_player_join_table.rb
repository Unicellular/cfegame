class CreateEventPlayerJoinTable < ActiveRecord::Migration
  def change
    create_join_table :players, :events do |t|
      t.index [:player_id, :event_id]
      t.index [:event_id, :player_id]
    end
  end
end
