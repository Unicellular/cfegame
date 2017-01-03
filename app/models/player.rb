class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :team
  has_many :cards, as: :cardholder, dependent: :destroy
  serialize :star_history, Array
  serialize :sustained, Hash

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

  def perform( rule, cards_used )
    rule.performed( self, cards_used, game )
  end

  def attacked( kind, point )
    team.attacked( point )
    { to: id, content: { attack: [ kind, point ] } }
  end

  def healed( kind, point )
    team.healed( point )
    { to: id, content: { heal: [ kind, point ] } }
  end

  def attached( effect )
    effect.each do |key, value|
      sustained[key] = value
    end
    #{ to: nil, content: { secret: }}
  end

  def using( card_ids )
    cards_used = card_ids.map do |c_id|
      Card.find(c_id)
    end
    return nil unless cards_used.all?{ |c| cards.include? c }
    cards_used.each do |card|
      #cards.delete card
      game.cards << card
    end
    cards_used
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
end
