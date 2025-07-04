class Rule < ApplicationRecord
  enum :form, { attack: 0, spell: 1, power: 2, become: 3 }
  enum :subform, { metal: 0, tree: 1, water: 2, fire: 3, earth: 4, physical: 5, special: 6,
                  active: 7, passive: 8, static: 9, mastery: 10, continuous: 11, inherit: 12 }
  enum :series, { basic: 0, star: 1, field: 2, hero: 3 }
  serialize :condition, coder: JSON
  serialize :material, coder: JSON
  serialize :formula, coder: JSON
  serialize :effect, coder: JSON
  has_one :rule
  has_many :event
  scope :action, -> { where(form: [:attack, :spell, :become]) }
  scope :active_power, -> { where(form: :power, subform: :active) }

  GENERATE = %w( metal water tree fire earth )
  OVERCOME = %w( metal tree earth water fire )

  def combination_test(cards)
    sts = stats(cards)
    material.all? do |key, value|
      case key
      when "and"
        subrule_list = value.map do |submaterial|
          Rule.new({"material": submaterial})
        end
        cards.combination(subrule_list[0].material["count"]).any? do |comb|
          result = subrule_list[0].combination_test(comb) && subrule_list[1].combination_test(cards-comb)
          if result
            tag_combination(cards, comb)
          end
          result
        end
      when "element", "level"
        value.all? do |k, v|
          if v == "all"
            sts[key][k] == cards.count
          else
            sts[key][k] >= v
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
        player.in_hero_list?(value, condition["inherit"])
      when "ruletype"
        value["form"] == executing_rule.form && (value["subform"].nil? || value["subform"] == executing_rule.subform)
      when "rule"
        value.any? do |rule_name, condition|
          # 當下正在執行的規則，所以不會在event裡
          result = executing_rule == Rule.find_by_name(rule_name)
          if condition.is_a?(Numeric) && condition >= 0
            if executing_rule.effect["point"].is_a?(Numeric)
              result &&= executing_rule.effect["point"] >= condition
            else
              result
            end
          else
            raise "rule[" + self.name + "] conditon wrong, should be a integer greater than 0"
          end
        end
      when "executed"
        value.any? do |rule_name, condition|
          event_list.where(rule: executing_rule).any? do |event|
            result = rule_name == executing_rule.name
            if condition.is_a?(Numeric) && event.effect["point"].is_a?(Numeric)
              # 陣法或能力的點數需符合條件。
              result &&= event.effect["point"] >= condition
            else
              result
            end
          end
        end
      when "history"
        stars = value.dup
        player.star_history.each do |star|
          stars.delete( star )
        end
        stars.empty?
      when "effect"
        value.all? do |ekey, evalue|
          event_list.where(rule: executing_rule).any? do |event|
            event.effect.has_key?(ekey) && event.effect[ekey].has_key?(evalue)
          end
        end
      else
        true
      end
    end
  end

  def restrict_test( player, cards )
    return true if player.annex["restrict"].nil?
    player.annex["restrict"].all? do |key, value|
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
      when "rule"
        # 預設value為array
        # (手牌沒有虛擬牌 且 施展的陣法不在value裡) 或 (出的牌中有虛擬牌 且 施展的陣法在value裡)
        (player.cards.all?{|card| !card.virtual} && !value.include?(name)) || (cards.any? {|card| card.virtual} && value.include?(name))
      end
    end
  end

  def total_test( cards, game, player )
    (attack? || spell? || become? || (active? && power?)) &&
      test_combination_with_mastery(cards, game, player) &&
      restrict_test(player, cards)
  end

  def get_mastery(game, player)
    Rule.where(form: "power", subform: "mastery").select do |rule|
      rule.condition_test(game, player) && rule.effect["rule"] == self.name
    end
  end

  def test_combination_with_mastery( cards, game, player )
    mastery_rules = get_mastery(game, player)
    all_rules = condition_test(game, player) ? mastery_rules.push(self) : mastery_rules
    all_rules.any? do |rule|
      rule.combination_test(cards)
    end
  end

  def tag_combination(cards, combination)
    # 基本上只是把combination移到array的後面，以利push進stack後會在最頂端
    combination.each do |c|
      rearranged = cards.index do |card|
        card.element == c.element && card.level == c.level
      end
      cards.push(cards.delete_at(rearranged))
    end
  end

  def find_biggest_sequence(stat, type)
    result = 0
    sorted_list = case type
    when "generate"
      GENERATE
    when "overcome"
      OVERCOME
    end
    (1..5).each do |sequence|
      circle_end = sequence == 5 ? 0 : sequence - 1
      (sorted_list + sorted_list[0,circle_end]).each_cons(sequence).each do |elem_list|
        is_bigger = elem_list.all? do |elem|
          stat["element"][elem] >= 1
        end
        if is_bigger 
          result = sequence
        end
      end
    end
    return result
  end

  def stats(cards)
    rs = {
      "element" => Hash.new(0),
      "level" => Hash.new(0)
    }
    # 計算各行數量、同行數量
    GENERATE.each do |elem|
      rs["element"][elem] = cards.count{ |card| card.element == elem }
      rs["element"]["!" + elem] = cards.count{ |card| card.element != elem }
      rs["element"]["same"] = rs["element"][elem] if rs["element"][elem] > rs["element"]["same"]
    end
    # 計算連續相生相剋數量
    rs["element"]["generate"] = find_biggest_sequence(rs, "generate")
    rs["element"]["overcome"] = find_biggest_sequence(rs, "overcome")
    # 計算各等級、同等級數量
    (1..5).each do |level|
      rs["level"][level.to_s] = cards.count{ |card| card.level == level }
      %i[!= > < >= <=].each do |opsym|
        rs["level"][opsym.to_s + level.to_s] = cards.count{ |card| card.level.send(opsym, level) }
      end
      rs["level"]["same"] = rs["level"][level.to_s] if rs["level"][level.to_s] > rs["level"]["same"]
    end
    rs["level"]["even"] = cards.count{|card| card.level.even?}
    rs["level"]["odd"] = cards.count{|card| card.level.odd?}
    rs["element"]["different"] = cards.uniq{ |card| card.element }.count
    rs["level"]["different"] = cards.uniq{ |card| card.level }.count
    rs["level"]["sum"] = cards.inject(0){ |sum, card| sum + card.level }
    rs
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
        unit = option[item.to_sym].pop
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

  def extract_calculation_option(cards, target)
    target_hand = target.cards.count unless target.nil? || target.respond_to?(:each)
    option = {target_hand: [target_hand]}
    option_cards = {}
    cards.each do |card|
      key = card.element.to_sym
      if option_cards.has_key?(key)
        option_cards[key].push(card.level)
      else
        option_cards[key] = [card.level]
      end
    end
    option.merge!(option_cards)
  end

  def executed( player, cards_used, game )
    target = get_target( player, game )
    last_player = game.last_player
    option = extract_calculation_option(cards_used, target)
    point = calculate(cards_used, option) unless formula.nil?
    modify_effect(game, player, last_player, target, point, cards_used)
    # 設定初始值
    result_effect = {}
    if target.respond_to?(:each)
      target.each do |t|
        target, result_effect = implemented(game, player, t, last_player, effect, cards_used)
      end
    else
      target, result_effect = implemented(game, player, target, last_player, effect, cards_used)
    end
    if is_action?
      last_player.annex.delete("counter")
      last_player.annex.delete("hidden")
      last_player.save
    end
    return target, result_effect
  end

  def implemented( game, player, target, last_player, effect, cards_used )
    # initialize object for the one in block
    affected = nil
    affected_way = nil
    result_effect = effect
    # 排除不需處理的效果
    not_process = ["point", "immune", "modified_point"]
    effect.each do |key, value|
      case key
      when "attack"
        target.attacked(value, subform)
      when "heal"
        target.healed(value, subform)
      when "self_attack"
        player.attacked(value, subform)
      when "self_heal"
        player.healed(value, subform)
      when "counter"
        player.attached("counter" => value )
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
        player.set_extra_draw(value)
      when "showhand"
        target.attached(showhand: value)
      when "hidden"
        player.attached(hidden: "counter")
      when "obtain"
        player.obtain( cards_used, value )
      when "summon"
        player.summon( value )
      when "eject"
        rank = get_rank(cards_used)
        affected = game.eject(value, rank)
      when "restrict"
        player.attached( restrict: value )
      when "reduce_affected"
        affected.each do |entity|
          entity.reduced( value )
        end
      when "win"
        game.decide_winner(player.team)
      when *not_process
        # do nothing
      when "gain"
        affected_way = player.change_if(condition_test(game, player), value)
      when "become"
        player.attached(hero: value)
      when "reduce"
        target.reduced(value)
      when "self_reduce"
        player.reduced(value)
      when "craft"
        player.attached(craft: value)
      when "invalid"
        player.attached(invalid: value)
      when "draw"
        set_draw_status(player, target, value)
      when "reveal"
        target.deleted(:hidden)
      when "take"
        player.attached(take: {amount: value["amount"], of: player.look(value["amount"], value["of"] - value["amount"])})
      else
        raise "This effect [" + key + "] is not implemented"
      end
    end
    # 處理完所有效果再來附加屬性，避免反震自傷時會再減半
    player.attached("element" => subform) if GENERATE.include?(subform)
    result_effect["affected_way"] = affected_way unless affected_way.nil?
    [target, result_effect]
  end

  def performed( player, cards_used, game )
    target, result_effect = executed( player, cards_used, game )
    turn = game.current_turn
    # 除非持續效果沒有影響，否則都需寫一個event
    turn.add_event(player, target, self, cards_used, result_effect) unless continuous? && !result_effect["affected_way"]
    target
  end

  def modify_effect(game, player, last_player, target, point, cards)
    # 留存原始點數
    effect["point"] = point
    effect["modified_point"] = point
    # 專精能力修改效果
    modify_with_mastery(game, player, cards)
    # 尋找會修改效果的規則
    fits = Rule.all_fitted(game, player, :static, self)
    fits.each do |rule|
      process_modify(rule) unless rule.effect["modify"].nil?
      effect["immune"] = rule.effect["immune"] unless rule.effect["immune"].nil?
    end
    # 處理與目標的互動
    if target.respond_to?(:each)
      target.each do |t|
        modify_with_target(t)
      end
    else
      modify_with_target(target)
    end
    # 處理反制效果
    modify_with_counter(player, last_player)
    effect
    #return point
  end

  def modify_with_mastery(game, player, cards)
    mastery_rules = get_mastery(game, player).select do |rule|
      rule.combination_test(cards)
    end
    mastery_rules.each do |rule|
      effect["point"] = effect["point"] + rule.effect["point"] unless effect["point"].nil? || rule.effect["point"].nil?
      effect["modified_point"] = effect["point"]
      effect["invalid"] = rule.effect["invalid"] unless rule.effect["invalid"].nil?
    end
  end

  def modify_with_counter(player, last_player)
    if player.annex["invalid"] == name || (last_player.annex["counter"] == "spell" && form == "spell" && !is_immune_from(last_player.annex["counter"]))
      effect.clear
      return nil
    end
    if last_player.annex["counter"] == "reveal"
      effect.delete("hidden")
    end
    ["attack", "heal", "shield", "deshield", "reduce"].each do |action|
      if effect.has_key?(action) && effect[action] == "point"
        effect[action] = effect["modified_point"]
      end
    end
    ["attack", "heal"].each do |action|
      # action可能是攻擊或被其他效果影響改成回復的攻擊，所以仍要判斷和反制效果的互動
      next unless effect.has_key?(action)
      if last_player.annex["counter"] == "attack" && form == "attack" && !is_immune_from(last_player.annex["counter"])
        effect[action] = 0
      elsif last_player.annex["counter"] == "split" && form == "attack" && !is_immune_from(last_player.annex["counter"])
        effect[action] = effect["modified_point"].fdiv(2).ceil
        effect["self_"+action] = effect["modified_point"].fdiv(2).ceil
      end
    end
  end

  def modify_with_target(target)
    return nil if target.nil?
    # copy（幻化）的效果最後還是會找到被複製的規則，所以用原規則的名字來判斷即可
    target.annex.each do |k, v|
      if v.respond_to?(:has_key?) && v.has_key?("escape") && v["escape"]["rule"].include?(name)
        effect.clear
      end
    end
  end

  def is_immune_from(counter)
    effect.has_key?("immune") && effect["immune"].include?(counter)
  end

  def process_modify(rule)
    case rule.effect["modify"]
    when "double"
      effect["modified_point"] = effect["modified_point"] * 2
    when "heal"
      effect["heal"] = effect.delete("attack")
    when "counter"
      effect.clear
    when "invalid"
      effect.delete("invalid")
    else
      raise "This effect [" + rule.effect["modify"] + "] of rule [" + rule.name + "] is not implemented"
    end
  end

  def work_with_counter( player, target, last_player, action, point )
    # action可能是攻擊或被其他效果影響改成回復的攻擊，所以仍要判斷和反制效果的互動
    if last_player.annex["counter"] == "attack" && form == "attack"
      target.send( action, 0, subform )
    elsif last_player.annex["counter"] == "split" && form == "attack"
      target.send( action, point.fdiv(2).ceil, subform )
      player.send( action, point.fdiv(2).ceil, subform )
    else
      target.send( action,  point, subform )
    end
    player.attached("element" => subform) if GENERATE.include? subform
  end

  def set_draw_status(player, target, draw_status)
    if draw_status["target"]
      target.attached(draw: draw_status["target"])
    else
      player.attached(draw: draw_status)
    end
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

  def get_rank(cards)
    sts = stats(cards)
    (1..5).each do |level|
      if sts["level"]["same"] == sts["level"][level.to_s]
        return level
      end
    end
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
