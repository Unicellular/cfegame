class Event < ApplicationRecord
  belongs_to :turn
  belongs_to :player
  belongs_to :target, class_name: "Player", optional: true
  belongs_to :rule, optional: true
  serialize :cards_used, coder: JSON
  serialize :effect, coder: JSON
end
