class Team < ActiveRecord::Base
  belongs_to :game
  has_many :players, dependent: :destroy
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

  def attacked( point )
    if life > point
      update( life: life - point )
    else
      update( life: 0 )
    end
  end

  def healed( point )
    if life_limit > life + point
      update( life: life + point )
    else
      update( life: life_limit )
    end
  end
end
