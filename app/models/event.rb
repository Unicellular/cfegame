class Event < ActiveRecord::Base
  belongs_to :turn
  belongs_to :player
  belongs_to :target, class_name: "Player"
  serialize :cards_used, Array
  serialize :effect, JSON
end
