class Card < ActiveRecord::Base
  belongs_to :cardholder,  polymorphic: true

  ELEMENTS = {
    metal: 1,
    tree: 2,
    water: 3,
    fire: 4,
    earth: 5,
  }
end
