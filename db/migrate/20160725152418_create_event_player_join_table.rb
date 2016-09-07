class CreateEventPlayerJoinTable < ActiveRecord::Migration
  def change
    create_table :event_player_links do |t|
      t.belongs_to :event
      t.belongs_to :player
    end
  end
end
