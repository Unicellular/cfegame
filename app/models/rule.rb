class Rule < ApplicationRecord
  enum form: { attack: 0, spell: 1, power: 2, become: 3 }
  enum subform: { metal: 0, tree: 1, water: 2, fire: 3, earth: 4, physical: 5, special: 6,
                  active: 7, passive: 8, static: 9, mastery: 10, continuous: 11, inherit: 12 }
  enum series: { basic: 0, star: 1, field: 2, hero: 3 }
  serialize :condition, JSON
  serialize :material, JSON
  serialize :formula, JSON
  serialize :effect, JSON
  has_one :rule
  has_many :event
  scope :action, -> { where(form: [:attack, :spell, :become]) }
  scope :active_power, -> { where(form: :power, subform: :active) }

  GENERATE = %w( metal water tree fire earth )
  OVERCOME = %w( metal tree earth water fire )

  def combination_test( cards )
    sts = stats( cards )
    material.all? do |key, value|
      case key
      when "element", "level"
        value.all? do |k, v|
          case k
          when "generate", "overcome"
            special_test( key, k, v, sts )
          else
            if v == "all"
              sts[key][k] == cards.count
            else
              sts[key][k] >= v
            end
          end
        end
      when "count"
        cards.count == value
      when "total_level"
        sts["level"]["sum"] >= value
      end
    end
  end

  def condition_test( game, player, executing_rule=nil )
    return true if condition.empty?
    event_list = game.current_turn.events
    condition.all? do |key, value|
      case key
      when "star"
        value.any? do |k, v|
          case v
          when "none"
            !(game.teams.any? { |t| t.has_star? k })
          when "mine"
            player.team.has_star? k
          when "other"
            game.teams.any? { |t| t.has_star? k && !(t.players.include? player) }
          end
        end
      when "field"
        game.field == value
      when "hero"
        player.is_hero?(value, condition["inherit"])
      when "ruletype"
        value["form"] == executing_rule.form && value["subform"] == executing_rule.subform
      when "rule"
        value.any? do |rule|
          rule == executing_rule.name
        end
      when "executed"
        value.all? do |rule_name, rule_condition|
          event_list.where( rule: Rule.find_by_name( rule_name ) ).any? do |event|
            if rule_condition.is_a? Numeric
              # 陣法或能力的點數需符合條件。
              event.effect["point"] >= rule_condition
            else
              true
            end
          end
        end
      when "history"
        stars = value.dup
        player.star_history.each do |star|
          stars.delete( star )
        end
        stars.empty?
      else
        true
      end
    end
  end

  def restrict_test( player, cards )
    return true if player.annex[:restrict].nil?
    player.annex[:restrict].all? do |key, value|
      case key
      when "ruleset"
        if cards.any?{ |card| card.virtual }
          if value.respond_to?( :find_index )
            !(value.find_index( series ).nil?)
          else
            series == value
          end
        else
          if value.respond_to?( :find_index )
            value.find_index( series ).nil?
          else
            series != value
          end
        end
      end
    end
  end

  def total_test( cards, game, player )
    (attack? || spell? || become? || (active? && power?)) && test_combination_with_mastery(cards, game, player) && condition_test(game, player) && restrict_test(player, cards)
  end

  def get_mastery(game, player)
    Rule.where(form: "power", subform: "mastery").select do |rule|
      rule.condition_test(game, player) && rule.effect["rule"] == self.name
    end
  end

  def test_combination_with_mastery( cards, game, player )
    mastery_rules = get_mastery(game, player)
    all_rules = mastery_rules.push(self)
    test_result = all_rules.any? do |rule|
      rule.combination_test(cards)
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
      rs["element"]["same"] = rs["element"][elem] if rs["element"][elem] > rs["element"]["same"]
    end
    (1..5).each do |level|
      rs["level"][level.to_s] = cards.count{ |card| card.level == level }
      rs["level"]["same"] = rs["level"][level.to_s] if rs["level"][level.to_s] > rs["level"]["same"]
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

  def executed( player, cards_used, game )
    target = get_target( player, game )
    target_hand = target.cards.count unless target.nil? || target.respond_to?(:each)
    last_player = game.last_player
    point = calculate( cards_used, target_hand: target_hand ) unless formula.nil?
    modify_effect( game, player, point )
    unless last_player.annex[:counter] == "spell" && form == "spell"
      if target.respond_to?(:each)
        target.each do |t|
          target, result_effect = implemented(game, player, t, last_player, effect, cards_used)
        end
      else
        target, result_effect = implemented(game, player, target, last_player, effect, cards_used)
      end
    end
    if is_action?
      last_player.annex.delete( :counter )
      last_player.annex.delete( :hidden )
      last_player.save
    end
    # 儲存原始點數
    result_effect["point"] = point
    return target, result_effect
  end

  def implemented( game, player, target, last_player, effect, cards_used )
    # initialize object for the one in block
    affected = nil
    result_effect = effect
    effect.each do |key, value|
      case key
      when "attack"
        work_with_counter( player, target, last_player, :attacked, value )
      when "heal"
        work_with_counter( player, target, last_player, :healed, value )
      when "counter"
        player.attached( counter: value )
      when "copy"
        last_act = nil
        Turn.where(game: game, phase: :end).order(number: :desc).each do |turn|
          last_act = Rule.action.joins(:event).where(events: { turn: turn }).first
          if last_act.name != "imitate"
            break
          end
        end
        if last_act && last_act.series == value
          target, result_effect = last_act.executed(player, cards_used, game)
        end
      when "shield"
        target.shielded( value )
      when "deshield"
        target.deshielded( value )
      when "freeze"
        target.attached( freeze: value )
      when "remove"
        target.attached( remove: value )
      when "exchange"
        game.exchange
      when "draw_extra"
        player.attached( draw_extra: value )
      when "showhand"
        target.attached( showhand: value )
      when "hidden"
        player.attached( hidden: :counter )
      when "obtain"
        player.obtain( cards_used, value )
      when "summon"
        player.summon( value )
      when "eject"
        affected = game.eject( value )
      when "restrict"
        player.attached( restrict: value )
      when "reduce_affected"
        affected.each do |entity|
          entity.reduced( value )
        end
      when "win"
        game.decide_winner( player.team )
      when "immune"
        # do nothing
      when "gain"
        player.change_if(condition_test(game, player), value)
      when "become"
        player.attached(hero: value)
      when "self_reduce"
        player.reduced(value)
      else
        raise "This effect [" + key + "] is not implemented"
      end
    end
    [target, result_effect]
  end

  def performed( player, cards_used, game )
    target, result_effect = executed( player, cards_used, game )
    turn = game.current_turn
    turn.events.create! player: player, target: target, rule: self, cards_used: cards_used.map { |c| c.to_hash }, effect: result_effect
    target
  end

  def modify_effect( game, player, point )
    if !effect["immune"]
      fits = Rule.all_fitted( game, player, :static, self )
      fits.each do |rule|
        case rule.effect["modify"]
        when "double"
          point = point * 2
        when "heal"
          effect["heal"] = effect.delete( "attack" )
        when "counter"
          effect.clear
        else
          raise "This effect [" + rule.name + "] is not implemented"
        end
      end
    end
    patch = {}
    effect.each do |key,value|
      if value == "point"
        patch[key] = point
      end
    end
    effect.merge!(patch)
    #return point
  end

  def work_with_counter( player, target, last_player, action, point )
    # action可能是攻擊或被其他效果影響改成回復的攻擊，所以仍要判斷和反制效果的互動
    if last_player.annex[:counter] == "attack" && form == "attack"
      target.send( action, 0, subform )
    elsif last_player.annex[:counter] == "split" && form == "attack"
      target.send( action, point.fdiv(2).ceil, subform )
      player.send( action, point.fdiv(2).ceil, subform )
    else
      target.send( action,  point, subform )
    end
    player.attached( element: subform ) if GENERATE.include? subform
  end

  def get_target( player, game )
    if target.is_a? Integer
      if target < 3
        game.players[ ( player.sequence + target ) % game.players.count ]
      elsif target == 3
        # 除了自己以外的所有人
        targets = game.players.to_a
        targets.delete(player)
        targets
      end
    end
  end

  def is_action?
    attack? || spell? || become?
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

  def self.all_fitted( game, player, subform, executing_rule=nil )
    rules = where( form: forms[:power], subform: subforms[subform] )
    rules.select do |rule|
      rule.condition_test( game, player, executing_rule )
    end
  end
end
