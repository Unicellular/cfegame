class Turn < ApplicationRecord
  has_many :events
  enum phase: { start: 0, action: 1, draw: 2, end: 3 }
  belongs_to :game

  def add_event(player, target, rule, cards_used, effect)
    events.create!(player: player, target: target, rule: rule, cards_used: cards_used.map{|c| c.to_hash }, effect: effect)
  end
end
