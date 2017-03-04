class Rule < ActiveRecord::Base
  enum form: [ :attack, :spell ]
  enum subform: { metal: 0, tree: 1, water: 2, fire: 3, earth: 4, physical: 5, special: 6,
                  active: 0, passive: 1, lasting: 2 }
  enum series: [ :base, :star, :field, :hero ]
  serialize :condition, JSON
  serialize :material, JSON
  serialize :formula, JSON
  serialize :effect, JSON
  has_one :rule
  has_many :event

  GENERATE = %w( metal water tree fire earth )
  OVERCOME = %w( metal tree earth water fire )

  def test( cards )
    sts = stats( cards )
    material.all? do |key, value|
      case key
      when "element", "level"
        value.all? do |k, v|
          case k
          when "same"
            sts[key].any?{ |k1, v1| v1 == v }
          when "generate", "overcome"
            special_test( key, k, v, sts )
          else
            sts[key][k] == v
          end
        end
      when "count"
        cards.count == value
      end
    end
  end

  # 4/5 generate or overcome elements are the same to 4/5 different elements
  def special_test( outer, inner, value, sts )
    elements_sorted = case inner
    when "generate"
      GENERATE
    when "overcome"
      OVERCOME
    end
    circle_end = value == 5 ? 0 : value - 1
    (elements_sorted + elements_sorted[0,circle_end]).each_cons(value).any? do |elem_list|
      elem_list.all? do |elem|
        sts[outer][elem] == 1
      end
    end
  end

  def stats( cards )
    rs = {
      "element" => Hash.new(0),
      "level" => Hash.new(0)
    }
    GENERATE.each do |elem|
      rs["element"][elem] = cards.count{ |card| card.element == elem }
    end
    (1..5).each do |level|
      rs["level"][level.to_s] = cards.count{ |card| card.level == level }
    end
    rs["element"]["different"] = cards.uniq{ |card| card.element }.count
    rs["level"]["different"] = cards.uniq{ |card| card.level }.count
    rs["level"]["sum"] = cards.inject(0){ |sum, card| sum + card.level }
    rs
  end

  def count( cards, cond )
    cards.count do |card|
      cond.all? do |key, value|
        case key
        when :element
          card.element == value.to_sym
        when :level
          card.level == value.to_i
        end
      end
    end
  end

  def calculate( cards, option = {} )
    sum = cards.inject(0) { |s, c| s + c.level }
    cal = formula.dup
    stack = []
    ops = %w( + - * / )
    until cal.empty?
      item = cal.shift
      case item
      when Integer
        unit = item
      when "sum"
        unit = sum
      when *ops
        temp = stack.pop(2)
        unit = temp[0].send(item, temp[1])
      else
        unit = option[item.to_sym]
      end
      stack.push(unit)
    end
    stack.pop
  end

  def formula=( value )
    # when calculating, we should shift it instead of pop it
    return nil unless value.respond_to?(:split)
    stack = []
    postfix = []
    lowers = %w( + - )
    uppers = %w( * / )
    value.split.each do |it|
      it = it.to_i if /^\d+$/.match(it)
      if uppers.include?(it) || lowers.include?(it)
        unless lowers.include?(stack[-1]) && uppers.include?(it)
          until stack.empty?
            postfix.push(stack.pop)
          end
        end
        stack.push(it)
      else
        postfix.push(it)
      end
    end
    until stack.empty?
      postfix.push(stack.pop)
    end
    write_attribute(:formula, postfix)
  end

  def executed( player, cards_used, game, turn_num )
    target = get_target( player, game )
    target_id = target.id unless target.nil?
    target_hand = target.cards.count unless target.nil?
    last_player = game.players[player.sequence-1]
    point = calculate( cards_used, target_hand: target_hand ) unless formula.nil?
    log = []
    player.attached( element: nil )
    effect.each do |key, value|
      value = point if value == "point"
      case key
      when "attack"
        if last_player.sustained["counter"] == "attack"
          log.push( target.attacked( 0, subform ) )
        elsif last_player.sustained["counter"] == "split"
          log.push( target.attacked( value.fdiv(2).ceil, subform ) )
          log.push( player.attacked( value.fdiv(2).ceil, subform ) )
        else
          log.push( target.attacked( value, subform ) )
        end
        player.attached( element: subform ) if GENERATE.include? subform
      when "heal"
        log.push( target.healed( value ) )
      when "counter"
        log.push( player.attached( counter: value ) )
      when "copy"
        last_act = Rule.joins( :event ).where( form: [ Rule.forms[:attack], Rule.forms[:spell] ], series: Rule.series[value], events: { turn_id: game.turns[turn_num-1].id } ).first
        log, target = last_act.executed( player, cards_used, game, turn_num - 1 )
      when "shield"
        log.push( target.shielded( value ) )
      when "deshield"
        log.push( target.deshielded( value ) )
      when "freeze"
        log.push( target.attached( freeze: value ) )
      when "remove"
        log.push( target.attached( remove: value ) )
      when "exchange"
        log.push( game.exchange( value ) )
      when "draw_extra"
        log.push( player.attached( draw_extra: value ) )
      when "showhand"
        log.push( target.attached( showhand: value ))
      end
    end unless last_player.sustained["counter"] == "spell" && form == "spell"
    return log, target
  end

  def performed( player, cards_used, game, turn_num )
    log, target = executed( player, cards_used, game, turn_num )
    turn = game.current_turn
    turn.events.create player: player, target: target, rule: self, effect: log, cards_used: cards_used.map { |c| c.to_hash }
  end

  def get_target( player, game )
    game.players[ ( player.sequence + effect["target"] ) % game.players.count ] if effect["target"].is_a? Integer
  end

  def self.interact( element1, element2 )
    generate_index = GENERATE.index( element1 )
    overcome_index = OVERCOME.index( element1 )
    case true
    when !generate_index.nil? && element2 == GENERATE[ ( generate_index + 1 ) % 5 ]
      :generate
    when !overcome_index.nil? && element2 == OVERCOME[ ( overcome_index + 1 ) % 5 ]
      :overcome
    when !generate_index.nil? && !overcome_index.nil? && element2 == element1
      :cancel
    else
      nil
    end
  end
end
