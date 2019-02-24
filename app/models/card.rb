class Card < ApplicationRecord
  belongs_to :cardholder,  polymorphic: true, touch: true
  enum element: Rule::GENERATE

  def to_hash
    { element: element, level: level }
  end
end
