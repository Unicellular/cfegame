class Team < ApplicationRecord
  belongs_to :game, autosave: true
  has_many :players, dependent: :destroy
  has_many :users, through: :players
  enum star: { nothing: 0, venus: 1, jupiter: 2, mercury: 3, mars: 4, saturn: 5 }
  serialize :annex, Hash

  def position_available?
    members_amount < maximum
  end

  def members_amount
    @count ||= players.count
  end

  def has_star?( star_name )
    star == star_name
  end

  def info( player )
    as_json({
      except: [ :created_at, :updated_at ]
    }).merge({
      members: players.map { |pl| pl.info( pl == player ) },
      action: []
    })
  end

  def reduced( point )
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
