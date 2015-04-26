class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :team
  has_many :cards, as: :cardholder

  def draw( amount )
    deck = team.game.deck
    space = hand_limit-cards.count
    amount = space >= amount ? amount : space
    deck.cards.order(:position).first(amount+1)
  end

  def discard( amount, no )
    return false if no < 0 || no >= amount
    temp_cards = draw( amount )
    dishand = temp_cards.delete_at(no)
    dishand.update(position: 999)
    team.game.cards << dishand
    temp_cards.each do |card|
      cards << card
    end
    cards
  end
end
