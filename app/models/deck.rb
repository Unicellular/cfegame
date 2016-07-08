class Deck < ActiveRecord::Base
  has_many :cards, -> { order(:position) }, as: :cardholder, dependent: :destroy
  belongs_to :game

  after_create do |deck|
    position = 0
    ActiveRecord::Base.transaction do
      (1..5).each do |value|
        (1..5).each do |level|
          copy = (1..3).include?(level) ? 4 : 3
          copy.times do
            cards.create( element: value, level: level, position: position )
            position += 1
          end
        end
      end
    end
  end

  def shuffle( todeck = false )
# 預設為要洗用過的牌，有特別設定時為洗牌組中的牌。
    handle = todeck ? cards : game.cards
    deck_count = todeck ? 0 : cards.count
    handle_count = handle.count
    deck_keys = todeck ? [] : cards.map { |c| c.id }

    deck_pos = (0...deck_count).map do |i|
      { position: i }
    end

    pos = (deck_count...(deck_count+handle_count)).map do |i|
      { position: i }
    end

    keys = handle.map { |c| c.id }

    ActiveRecord::Base.transaction do
      Card.update( keys, pos.shuffle )
      Card.update( deck_keys, deck_pos )
      handle.each do |c|
        cards << c
      end unless todeck
    end

    self
  end

  def recycle( card )
    position = cards.minimum(:position) - 1

    ActiveRecord::Base.transaction do
      card.update(position: position)
      cards << card
    end
  end

end
