class CreateCardEventJoinTable < ActiveRecord::Migration
  def change
    create_table :card_event_links do |t|
      t.belongs_to :card
      t.belongs_to :event
    end
  end
end
