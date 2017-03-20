class Turn < ActiveRecord::Base
  has_many :events
  enum phase: { start: 0, action: 1, draw: 2, end: 3 }
  belongs_to :game
end
