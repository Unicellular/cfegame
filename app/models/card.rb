class Card < ActiveRecord::Base
  belongs_to :cardholder,  polymorphic: true

  ELEMENTS = {
    metal: 1,
    water: 2,
    tree: 3,
    fire: 4,
    earth: 5
  }

  EMPOWER = [
    :metal, :water, :tree, :fire, :earth
  ]

  SURPASS = [
    :metal, :tree, :earth, :water, :fire
  ]
end
