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

  GENERATE = %w( metal water tree fire earth )
  OVERCOME = %w( metal tree earth water fire )

  def test( cards )
    material.all? do |key, value|
      #puts key, value, count( cards, key )
      if GENERATE.include? key
        count( cards, key ) == value
      elsif key == "count"
        cards.count == value
      end
    end
  end

  def count( cards, element )
    cards.count do |card|
      card.element.to_s == element
    end
  end

  def calculate( cards )
    sum = cards.inject(0) { |s, c| s + c.level }
    cal = formula.dup
    stack = []
    ops = %w( + - * / )
    until cal.empty?
      item = cal.shift
      item = sum if item == "sum"
      if ops.include? item
        temp = stack.pop(2)
        item = temp[0].send(item, temp[1])
      end
      stack.push(item)
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

  def performed( player, cards_used, game )
    if test(cards_used)
      target = get_target( player, game )
      target_id = target.id unless target.nil?
      point = calculate( cards_used ) unless formula.nil?
      last_player = game.players[player.sequence-1]
      log = []
      effect.each do |key, value|
        value = point if value == "point"
        case key
        when "attack"
          if last_player.sustained["counter"] == "attack"
            log.push( target.attacked( subform, 0 ) )
          elsif last_player.sustained["counter"] == "split"
            log.push( target.attacked( subform, value / 2 ) )
            log.push( player.attacked( subform, value / 2 ) )
          else
            log.push( target.attacked( subform, value ) )
          end
        when "heal"
          log.push( target.healed( value ) )
        when "counter"
          log.push( player.attached( counter: value ) )
        end
        #log[:content][key] = [ subform, point ] unless key == "target"
      end unless last_player.sustained["counter"] == "spell" && form == :spell
      turn = game.current_turn
      turn.events.create player: player, cards_used: cards_used, target: target, effect: log
    end
  end

  def get_target( player, game )
    game.players[player.sequence + effect["target"]] if effect["target"].is_a? Integer
  end
end
