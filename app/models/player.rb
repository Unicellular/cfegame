class Player < ActiveRecord::Base
  belongs_to :user
  belongs_to :team
  has_many :cards, as: :cardholder, dependent: :destroy
  has_many :event
  serialize :star_history, Array
  serialize :sustained, Hash

  def draw( amount )
    return nil unless is_phase?( :draw )
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
    set_phase( :end )
    save
    dishand
  end

  def recycle( card )
    return nil unless is_phase?( :start )
    game.deck.recycle( card )
  end

  def perform( rule, cards_used )
    return nil unless is_phase?( :start )
    return nil unless sustained[:freeze].nil?
    return nil unless cards_used.all?{ |c| cards.include? c }
    set_phase( :action )
    cards_used.each do |card|
      game.cards << card
    end
    target = rule.performed( self, cards_used, game, game.turn ) if rule.test( cards_used )
    set_phase( :draw ) unless target && target.sustained[:showhand]
  end

  def select( target, cards_selected )
    puts "begining"
    return nil unless is_phase?( :action )
    puts "1st check"
    return nil if ( target.sustained[:remove] && target.sustained[:remove] > cards_selected.count )
    puts "2nd check"
    if target.sustained.has_key?( :remove )
      puts "in the if"
      target.removed( cards_selected.first( target.sustained[:remove] ) )
    end
    target.sustained.delete( :remove )
    target.sustained.delete( :showhand )
    target.save
    set_phase( :draw )
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

  def turn_end
    return nil unless is_phase?( :end ) || ( sustained[:freeze] && is_phase?( :start ) )
    if sustained.has_key?( :freeze )
      sustained[:freeze] -= 1
      if sustained[:freeze] == 0
        sustained.delete( :freeze )
      end
    end
    save
    game.turn_end
  end

  def set_phase( phase )
    game.current_turn.update( phase: phase )
  end

# happens in opponent's turn
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
  end

# request information, not updated anything
  def info( is_public )
    last_events = Event.joins( :turn ).where( player: self, rule: Rule.action, turn: game.turns ).order( Turn.arel_table[:number].desc ).first(2)
    last_player = game.last_player
    as_json({
      except: [ :created_at, :updated_at, :sustained ]
    }).merge({
      hands: hands( is_public ).as_json,
      last_acts: last_events.map do |event|
        # ( event.turn == game.last_turn || ( event.turn == current_turn && ( current_turn.start? || current_turn.action? ) ) )
        if event.rule.passive? && !is_public && ( event.turn == game.current_turn || ( event.turn == game.last_turn && last_player.sustained[:hidden] == :counter ) )
          { cards_count: event.cards_used.count }
        else
          event.as_json({
            only: :cards_used
          }).merge({
            rule_name: event.rule.chinese_name
          })
        end
      end,
      sustained: sustained.select do |key, value|
        key != sustained[:hidden]
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

  def game
    @game || team.game
  end

  def is_phase?( phase )
    return false unless game.turn_player == self
    check_method = (phase.to_s + "?").to_sym
    game.current_turn.send( check_method )
  end
end
