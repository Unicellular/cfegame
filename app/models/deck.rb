class Deck < ActiveRecord::Base
  has_many :cards, as: :cardholder
  belongs_to :game

  after_create do |deck|
    position = 1
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

  def shuffle
    handle = cards
    90.downto(2) do |i|
      j = rand i
      icard = handle[i-1]
      jcard = handle[j-1]
      icard.position = j
      jcard.position = i
    end
    handle.each {|card| card.save}
  end
end
