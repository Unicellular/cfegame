class Player < ApplicationRecord
  belongs_to :user
  belongs_to :team, autosave: true
  has_many :cards, as: :cardholder, dependent: :destroy
  has_many :event
  serialize :star_history, Array
  serialize :annex, JSON

  after_initialize :initialize_defaults, :if => :new_record?

  def initialize_defaults
      self.annex = {}
  end

  def draw(amount, discard = 1)
    return nil unless is_phase?( :draw ) || ( is_phase?( :start ) && cards.count == 0 )
    amount = amount + annex["draw_extra"] unless annex["draw_extra"].nil?
    amount = 0 if annex["draw"] == "none"
    look(amount, discard)
  end

  def look(amount, discard)
    deck = game.deck
    space = hand_limit - cards.count
    amount = space >= amount ? amount : space
    if amount == 0
      return []
    end
    if deck.cards.count < amount + discard
      deck.shuffle
    end
    deck.cards.order(:position).first(amount + discard)
  end

  def discard(amount, dishand, discard = 1)
    drawed_cards = draw(amount, discard)
    # 檢查捨棄的牌是否在抽起來的牌中
    return nil unless drawed_cards.include?(dishand) || (dishand.nil? && drawed_cards.empty?)
    unless dishand.nil?
      drawed_cards.delete(dishand)
      game.discarded(dishand)
      game.current_turn.add_event(self, nil, nil, [], {discard: dishand.to_hash, draw: drawed_cards.count})
    end
    unless drawed_cards.empty?
      drawed_cards.each do |card|
        cards << card
      end
    end
    draw_extra = annex["draw_extra"] ? annex["draw_extra"] : 0
    annex["take"] = {"amount" => amount + draw_extra, "of" => amount + draw_extra + discard}
    take(drawed_cards, [dishand])
    annex.delete("draw_extra")
    annex.delete("draw")
    set_phase(:end)
    save
    dishand
  end

  def take(looked_cards, dishand_list)
    return nil unless dishand_list.all?{ |card| looked_cards.include?(card)} || (dishand_list.empty? && looked_cards.empty?)
    unless dishand_list.empty?
      dishand_list.each do |card|
        looked_cards.delete(card)
        game.discarded(card)
      end
    end
    if looked_cards.empty? || looked_cards.count != annex["take"]["amount"]
      raise "the amount of taking cards is wrong"
    end
    looked_cards.each do |card|
      cards << card
    end
    annex.delete("look")
    annex.delete("take")
    save
  end

  def recycle( card )
    return nil unless is_phase?( :start )
    game.deck.recycle( card )
    reduced( card.level * 2 )
  end

  def perform( rule, cards_used )
    return nil unless is_phase?( :start )
    return nil unless annex["freeze"].nil?
    return nil unless cards_used.all?{ |c| cards.include? c }
    ActiveRecord::Base.transaction do
      #puts "beginning"
      set_phase( :action ) if rule.is_action?
      cards_used.each do |card|
        game.cards << card
      end
      #puts "before perform"
      target = rule.performed(self, cards_used, game) if rule.total_test(cards_used, game, self)
      set_phase(:draw) unless target && target.annex["showhand"] || !rule.is_action?
    end
    trigger(rule)
  end

  def trigger( last_rule )
    # 避免無窮迴圈，先暫定最多觸發三次
    3.times do
      trigger_rules = Rule.all_fitted(game, self, :passive, last_rule)
      trigger_rules.each do |rule|
        rule.performed(self, [], game)
        last_rule = rule
      end
    end
  end

  # 行動階段專用的搶牌
  def select( target, cards_selected )
    return nil unless is_phase?( :action )
    if !target.annex["remove"].nil?
      choose(target, cards_selected)
    end
    target.annex.delete("showhand")
    target.save
    set_phase( :draw )
  end

  def choose(target, cards_selected)
    cards_moved = target.removed(cards_selected, self)
    game.current_turn.events.create! player: self, target: target, rule: nil, cards_used: [], effect: { cards_moved: cards_moved, target_hand: target.cards }
  end

  def removable?(cards_selected)
    # 目標需有移除註記
    return false unless annex["remove"]
    # 目標需持有所有待移除的牌
    return false unless cards_selected.all?{ |c| cards.include? c } 
    # 若有設定條件，則需符合條件
    condition_match = true
    remaining_cards = cards - cards_selected
    if annex["remove"]["condition"] && annex["remove"]["condition"]["level"] == "max"
      condition_match = remaining_cards.all?{|c| cards_selected.all?{|cs| cs.level >= c.level}}
    end
    return false unless condition_match
    # 如果目標的手牌足夠，則要儘可能多的移除
    amount = annex["remove"]["amount"]
    if cards.count >= amount
      amount == cards_selected.count
    else
      cards.count == cards_selected.count
    end
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
    return nil unless is_phase?(:end) || (annex["freeze"] && is_phase?(:start))
    if annex.has_key?("freeze")
      annex["freeze"] -= 1
      if annex["freeze"] == 0
        annex.delete("freeze")
      end
    end
    if annex.has_key?("restrict")
      annex.delete("restrict")
    end
    save
    game.turn_end
  end

  def turn_start
    deleted("element")
  end

  def set_phase( phase )
    game.current_turn.update( phase: phase )
  end

  def craft(modified)
    # 找到本回合最近使用發動能力的事件
    event = game.current_turn.events.joins(:rule).where(rules: {form: :power, subform: :active}).order(created_at: :desc).first
    cards_used = event.cards_used.map do |attr|
      Card.new(attr)
    end
    new_card = obtain(cards_used, modified)
    deleted("craft")
    # 將組好的新卡寫入事件中
    # 將等級寫進point裡，以利後續判斷精研，因為規則上是小於，所以要是負的
    event.effect = event.effect.merge!(crafted: new_card, point: -new_card.level)
    event.save!
  end

# happens in opponent's turn
  def attacked( point, kind=nil )
    if shield == 0
      case Rule.interact(kind, annex["element"])
      when :generate
        team.healed( point )
      when :overcome
        team.reduced( point * 2 )
      when :cancel
        team.reduced( point.fdiv(2).ceil )
      else
        point_modi = point
        annex.each do |k, v|
          if v.respond_to?(:has_key?) && v.has_key?(kind)
            case v[kind]
            when "half"
              point_modi = point.fdiv(2).ceil
            when "none"
              point_modi = 0
            end
          end
        end
        team.reduced( point_modi )
      end
    elsif kind == "physical"
      deshielded( point * 2 )
    else
      deshielded( point )
    end
  end

  def reduced( point, kind=nil )
    team.reduced( point )
  end

  def healed( point, kind=nil )
    case Rule.interact( kind, annex["element"] )
    when :overcome
      team.healed( point * 2 )
    when :cancel
      team.healed( point.fdiv(2).ceil )
    else
      team.healed( point )
    end
  end

  def attached( effect )
    effect.each do |key, value|
      annex[key] = value
    end
    save
  end

  def deleted( key )
    annex.delete( key )
    save
  end

  def change_if( condition, effect )
    affected_way = nil
    effect.each do |key, value|
      if condition && !annex.has_key?(key)
        annex[key] = value
        affected_way = "gain"
      elsif !condition && annex.has_key?(key)
        annex.delete(key)
        affected_way = "remove"
      end
    end
    save
    affected_way
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

  def removed(cards_selected, reciever)
    raise "the cards of target #{id} is not removable." unless removable?(cards_selected)
    remove_number = annex["remove"]["amount"]
    move_to = reciever
    if annex["remove"]["to"] == "deck"
      move_to = game.deck
      top_position = move_to.cards.minimum(:position)
      cards_selected.first(remove_number).each_with_index do |c, i|
        c.update(position: top_position - 1 - i)
      end
    end
    annex.delete("remove")
    move_to.cards << cards_selected
  end

  def obtain(used_cards, modified)
    old_card = used_cards.first
    card_attrs = { level: old_card.level, element: old_card.element, virtual: true }.merge( modified )
    new_card = Card.new( card_attrs )
    cards << new_card
    new_card
  end

  def summon( entity )
    entity.each do |key, value|
      case key
      when "star"
        team.star = value.to_sym
        star_history << value unless star_history.include? value
      when "field"
        game.field = value.to_sym
      end
    end
    save
  end

  def in_hero_list?(hero_list, inherit=true)
    return false unless annex.has_key?("hero")
    inherit = true if inherit.nil?
    return is_hero?(hero_list, inherit) unless hero_list.respond_to?(:each)
    hero_list.any? do |hero|
      is_hero?(hero, inherit)
    end
  end

  def is_hero?(hero, inherit=true)
    if inherit
      annex["hero"].include?(hero)
    else
      annex["hero"][0] == hero
    end
  end

  def lengendary?
    annex["lengendary"]
  end

  def set_extra_draw(amount)
    if annex["draw_extra"].nil?
      attached(draw_extra: amount)
    else
      annex["draw_extra"] += amount
    end
    save
  end

# request information, not updated anything
  def info( is_public )
    last_events = Event.joins( :turn ).where( player: self, rule: Rule.action, turn: game.turns ).order( Turn.arel_table[:number].desc ).first(2)
    last_player = game.last_player
    if annex.nil?
      v_annex = nil
    else
      v_annex = annex.select do |key, value|
        key != annex["hidden"]
      end
    end
    as_json({
      except: [ :created_at, :updated_at, :annex ]
    }).merge({
      hands: hands( is_public ).as_json,
      last_acts: last_events.map do |event|
        # ( event.turn == game.last_turn || ( event.turn == current_turn && ( current_turn.start? || current_turn.action? ) ) )
        if event.rule.passive? && !is_public && ( event.turn == game.current_turn || ( event.turn == game.last_turn && last_player.annex["hidden"] == "counter" ) )
          { cards_count: event.cards_used.count }
        else
          event.as_json({
            only: :cards_used
          }).merge({
            rule_name: event.rule.chinese_name
          })
        end
      end,
      annex: v_annex
    })
  end

  def hands( is_public )
    if is_public || annex["showhand"]
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
