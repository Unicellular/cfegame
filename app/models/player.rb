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

  def discard( amount, dishand )
    drawed_cards = draw( amount )
    return nil unless drawed_cards.include? dishand
    game = team.game
    drawed_cards.delete(dishand)
    old_discard = game.cards.find_by(position: 90)
    old_discard.update(position: dishand.position) unless old_discard.nil?
    dishand.update(position: 90)
    game.cards << dishand
    drawed_cards.each do |card|
      cards << card
    end
    dishand
  end

  # def move( hands, spell )
  #   return nil unless cards.include hands && hands.form spell
  # end
end
