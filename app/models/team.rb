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
      except: [ :created_at, :updated_at ]
    }).merge({
      members: players.map { |pl| pl.info( pl == player ) },
      action: []
    })
  end

  def attacked( point, kind=nil )
    if life > point
      update( life: life - point )
    else
      update( life: 0 )
    end
  end

  def healed( point, kind=nil )
    if life_limit > life + point
      update( life: life + point )
    else
      update( life: life_limit )
    end
  end
end
