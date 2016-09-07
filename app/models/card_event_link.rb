class CardEventLink < ActiveRecord::Base
  belongs_to :card
  belongs_to :event
end
