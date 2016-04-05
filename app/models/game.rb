class Game < ActiveRecord::Base
  has_many :teams
  has_many :players, through: :teams
  has_many :cards, as: :cardholder
  has_one :deck

  def self.open( user, game_options: {}, team_options: {} )
    game = self.create( game_options )
    team_amount ||= game.team_amount
    teams = game.teams
    team_amount.times do
      teams.create( team_options )
    end
    game.deck = Deck.new
    game.deck.shuffle
    game.join_with( user, teams[0] )
  end

  def join_with( user, team )
    if team.position_available?
      user.players << team.players.create
    end
    self
  end

  def ready?
    teams.all? do |team|
      !(team.position_available?)
    end
  end

  def start( player )
    player.cards << deck.cards.order(:position).first(player.hand_limit) if player.cards.count == 0
    player.team.as_json( except: [ :created_at, :updated_at ] ).merge(
      player.as_json({
        except: [ :created_at, :updated_at ],
        root: true,
        include: :cards
      })
    )
  end

  def current_player( user )
    players.where(user: user)
  end
end
