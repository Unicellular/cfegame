module Helpers
  def player_perform_rule(player, rule_name, card_attrs)
    used_cards = get_cards(card_attrs)
    rule = Rule.find_by_name(rule_name)
    player.cards = used_cards
    player.perform(rule, used_cards)
  end

  def get_cards(card_attrs)
    card_attrs.map do |attr|
      Card.new(element: attr[0], level: attr[1])
    end
  end
end
