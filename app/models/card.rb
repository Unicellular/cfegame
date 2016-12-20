class Card < ActiveRecord::Base
  belongs_to :cardholder,  polymorphic: true, touch: true
  enum element: Rule::GENERATE
end
