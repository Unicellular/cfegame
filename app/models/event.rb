class Event < ActiveRecord::Base
  belongs_to :turn
  has_one :event_player_link
  has_many :card_event_links
  has_one :player, through: :event_player_link
  has_many :cards, through: :card_event_links
  serialize :effect, JSON
end
