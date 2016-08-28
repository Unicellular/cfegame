class Rule < ActiveRecord::Base
  enum form: [ :attack, :spell ]
  enum subform: { metal: 0, tree: 1, water: 2, fire: 3, earth: 4, phyiscal: 5, special: 6,
                  active: 0, passive: 1, lasting: 2 }
  enum series: [ :base, :star, :field, :hero ]
  serialize :condition, JSON
  serialize :material, JSON
  serialize :formula, JSON
  serialize :effect, JSON
  has_one :rule

  EMPOWER = %w( metal water tree fire earth )

  SURPASS = %w( metal tree earth water fire )

  def test( cards )
    material.all? do |key, value|
      #puts key, value, count( cards, key )
      if EMPOWER.include? key
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
      seq = player.sequence
      point = calculate( cards_used )
      target = game.players[seq + effect["target"]]
      effect.each do |key, value|
        case key
        when "attack"
          target.attacked( point )
        when "heal"
          target.healed( point )
        end
      end
    end
  end
end
