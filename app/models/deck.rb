class Deck < ActiveRecord::Base
  has_many :cards, as: :cardholder
  belongs_to :game

  after_create do |deck|
    position = 0
    Card::ELEMENTS.each do |element, value|
      (1..5).each do |level|
        copy = (1..3).include?(level) ? 4 : 3
        copy.times do
          cards.create( element: value, level: level, position: position )
          position += 1
        end
      end
    end
  end

  def shuffle( todeck )
    handle = todeck ? cards : game.cards.where.not(position: 90)
    count = handle.count
    tail = todeck ? 0 : cards.maximum(:position)
    count.downto(2) do |i|
      j = rand(i-1)+1
      icard = handle[i-1]
      jcard = handle[j-1]
      icard.position = j + tail
      jcard.position = i + tail
    end
    cards.order(:position).each_with_index do |card, i|
      card.update position: i
    end if todeck
    handle.each do |card|
      cards << card
      card.save
    end
  end
end
