class Event < ActiveRecord::Base
  belongs_to :turn
  has_one :player, through: :events_players
  has_many :cards, through: :cards_events
end
