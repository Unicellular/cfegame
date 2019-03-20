class Player < ApplicationRecord
  belongs_to :user
  belongs_to :team
  has_many :cards, as: :cardholder, dependent: :destroy
  has_many :event
  serialize :star_history, Array
  serialize :annex, Hash

  def draw( amount )
    return nil unless is_phase?( :draw ) || ( is_phase?( :start ) && cards.count == 0 )
    deck = game.deck
    space = hand_limit-cards.count
    amount = amount + annex[:draw_extra] unless annex[:draw_extra].nil?
    amount = space >= amount ? amount : space
    if deck.cards.count < amount + 1
      deck.shuffle
    end
    deck.cards.order(:position).first(amount+1)
  end

  def discard( amount, dishand )
    drawed_cards = draw( amount )
    return nil unless drawed_cards.include? dishand
    drawed_cards.delete( dishand )
    game.discarded( dishand )
    drawed_cards.each do |card|
      cards << card
    end
    annex.delete( :draw_extra )
    set_phase( :end )
    save
    dishand
  end

  def recycle( card )
    return nil unless is_phase?( :start )
    game.deck.recycle( card )
    reduced( card.level * 2 )
  end

  def perform( rule, cards_used )
    return nil unless is_phase?( :start )
    return nil unless annex[:freeze].nil?
    return nil unless cards_used.all?{ |c| cards.include? c }
    ActiveRecord::Base.transaction do
      #puts "beginning"
      set_phase( :action ) if rule.is_action?
      cards_used.each do |card|
        game.cards << card
      end
      #puts "before perform"
      target = rule.performed( self, cards_used, game, game.turn ) if rule.total_test( cards_used, game, self )
      set_phase( :draw ) unless target && target.annex[:showhand] || !rule.is_action?
    end
  end

  def select( target, cards_selected )
    return nil unless is_phase?( :action )
    return nil if ( target.annex[:remove] && target.annex[:remove] > cards_selected.count )
    if target.annex.has_key?( :remove )
      cards_moved = target.removed( cards_selected.first( target.annex[:remove] ) )
    end
    target.annex.delete( :remove )
    target.annex.delete( :showhand )
    target.save
    game.current_turn.events.create! player: self, target: target, rule: nil, cards_used: [], effect: { cards_moved: cards_moved, target_hand: target.cards }
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
    return nil unless is_phase?( :end ) || ( annex[:freeze] && is_phase?( :start ) )
    if annex.has_key?( :freeze )
      annex[:freeze] -= 1
      if annex[:freeze] == 0
        annex.delete( :freeze )
      end
    end
    if annex.has_key?( :restrict )
      annex.delete( :restrict )
    end
    save
    game.turn_end
  end

  def turn_start
    attached( element: nil )
  end

  def set_phase( phase )
    game.current_turn.update( phase: phase )
  end

# happens in opponent's turn
  def attacked( point, kind=nil )
    if shield == 0
      case Rule.interact( kind, annex[:element] )
      when :generate
        team.healed( point, kind )
      when :overcome
        team.reduced( point * 2, kind )
      when :cancel
        team.reduced( point.fdiv(2).ceil, kind )
      else
        team.reduced( point, kind )
      end
    elsif kind == "physical"
      deshielded( point * 2 )
    else
      deshielded( point )
    end
  end

  def reduced( point, kind=nil )
    team.reduced( point, kind )
  end

  def healed( point, kind=nil )
    team.healed( point, kind )
  end

  def attached( effect )
    effect.each do |key, value|
      annex[key] = value
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

  def obtain( used_cards, modified )
    old_card = used_cards.first
    card_attrs = { level: old_card.level, element: old_card.element, virtual: true }.merge( modified )
    new_card = Card.new( card_attrs )
    cards << new_card
  end

  def summon( entity )
    entity.each do |key, value|
      case key
      when "star"
        team.star = value.to_sym
        star_history << value unless star_history.include? value
      end
    end
    team.save
    save
  end

# request information, not updated anything
  def info( is_public )
    last_events = Event.joins( :turn ).where( player: self, rule: Rule.action, turn: game.turns ).order( Turn.arel_table[:number].desc ).first(2)
    last_player = game.last_player
    as_json({
      except: [ :created_at, :updated_at, :annex ]
    }).merge({
      hands: hands( is_public ).as_json,
      last_acts: last_events.map do |event|
        # ( event.turn == game.last_turn || ( event.turn == current_turn && ( current_turn.start? || current_turn.action? ) ) )
        if event.rule.passive? && !is_public && ( event.turn == game.current_turn || ( event.turn == game.last_turn && last_player.annex[:hidden] == :counter ) )
          { cards_count: event.cards_used.count }
        else
          event.as_json({
            only: :cards_used
          }).merge({
            rule_name: event.rule.chinese_name
          })
        end
      end,
      annex: annex.select do |key, value|
        key != annex[:hidden]
      end
    })
  end

  def hands( is_public )
    if is_public || annex[:showhand]
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
