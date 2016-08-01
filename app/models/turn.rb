class Turn < ActiveRecord::Base
  has_many :events
  belongs_to :game
end
