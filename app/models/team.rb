class Team < ActiveRecord::Base
  belongs_to :game
  has_many :players
  has_many :users, through: :players

  def position_available?
    members_amount < maximum
  end

  def members_amount
    @count ||= players.count
  end
end
