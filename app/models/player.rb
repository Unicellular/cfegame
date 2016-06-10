class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :team
  has_many :cards, as: :cardholder

  def game
    @game || team.game
  end

  def draw( amount )
    deck = game.deck
    space = hand_limit-cards.count
    amount = space >= amount ? amount : space
    deck.cards.order(:position).first(amount+1)
  end

  def discard( amount, dishand )
    drawed_cards = draw( amount )
    return nil unless drawed_cards.include? dishand
    drawed_cards.delete(dishand)
    game.cards << dishand
    drawed_cards.each do |card|
      cards << card
    end
    dishand
  end

  def info( is_public )
    as_json({
      except: [ :created_at, :updated_at ],
      root: true
    }).merge({
      hands: hands( is_public ).as_json
    })
  end

  def hands( is_public )
    if is_public
      return cards
    else
      return cards.count
    end
  end

  def using( card_ids )
    cards_used = card_ids.map do |c_id|
      Card.find(c_id)
    end
    return nil unless cards_used.all?{ |c| cards.include? c }
    cards_used.each do |card|
      cards.delete card
      game.cards << card
    end
    cards_used
  end
  # def move( hands, spell )
  #   return nil unless cards.include hands && hands.form spell
  # end
end
