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

  def info( player )
    as_json({
      except: [ :created_at, :updated_at ],
      root: true
    }).merge({
      members: players.map { |pl| pl.info( pl == player ) }
    })
  end
end
