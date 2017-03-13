class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :team
  has_many :cards, as: :cardholder, dependent: :destroy
  has_many :event
  serialize :star_history, Array
  serialize :sustained, Hash

  def game
    @game || team.game
  end

  def draw( amount )
    deck = game.deck
    space = hand_limit-cards.count
    amount = amount + sustained[:draw_extra] unless sustained[:draw_extra].nil?
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
    sustained.delete( :draw_extra )
    dishand
  end

  def perform( rule, cards_used )
    return nil unless cards_used.all?{ |c| cards.include? c }
    return nil unless sustained[:freeze].nil?
    cards_used.each do |card|
      game.cards << card
    end
    rule.performed( self, cards_used, game, game.turn ) if rule.test( cards_used )
  end

  def attacked( point, kind=nil )
    if shield == 0
      case Rule.interact( kind, sustained[:element] )
      when :generate
        team.healed( point, kind )
      when :overcome
        team.attacked( point * 2, kind )
      when :cancel
        team.attacked( point.fdiv(2).ceil, kind )
      else
        team.attacked( point, kind )
      end
    elsif kind == "physical"
      deshielded( point * 2 )
    else
      deshielded( point )
    end
  end

  def healed( point, kind=nil )
    team.healed( point, kind )
  end

  def attached( effect )
    effect.each do |key, value|
      sustained[key] = value
    end
    save
  end

  def shielded( value )
    update( shield: value )
  end

  def deshielded( value )
    if shield > value
      update( shield: shield - value )
    else
      update( shield: 0 )
    end
  end

  def removed( cards_selected )
    return nil unless cards_selected.all?{ |c| cards.include? c }
    deck = game.deck
    decktop = deck.cards.minimum( :position )
    cards_selected.each_with_index do |c, i|
      c.update( position: decktop - 1 - i )
    end
    deck.cards << cards_selected
    sustained.delete( :remove )
    sustained.delete( :showhand )
    save
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
    last_events = Event.joins( :turn ).where( player: self, rule: Rule.action, turn: game.turns ).order( Turn.arel_table[:number].desc ).first(2)
    as_json({
      except: [ :created_at, :updated_at ]
    }).merge({
      hands: hands( is_public ).as_json,
      last_acts: last_events.map do |event|
        event.as_json({
          only: :cards_used
        }).merge({
          rule_name: event.rule.chinese_name
        })
      end
    })
  end

  def hands( is_public )
    if is_public || sustained[:showhand]
      return cards
    else
      return cards.count
    end
  end

  def turn_end
    if sustained.has_key?( :freeze )
      sustained[:freeze] -= 1
      if sustained[:freeze] == 0
        sustained.delete( :freeze )
      end
    end
    save
    game.turn_end
  end
end
