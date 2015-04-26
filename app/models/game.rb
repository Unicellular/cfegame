class Game < ActiveRecord::Base
  has_many :teams
  has_many :cards, as: :cardholder
  has_one :deck

  def self.open( user, game_options: {}, team_options: {} )
    game = self.create( game_options )
    team_amount ||= game.team_amount
    team_amount.times do
      game.teams.create( team_options )
    end
    game.deck = Deck.create
    game.join_with( user, 0 )
  end

  def join_with( user, teamno )
    team = teams[teamno]
    if team.position_available?
      user.players << team.players.create
    end
    self
  end
end
