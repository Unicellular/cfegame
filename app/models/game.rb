class Game < ActiveRecord::Base
  has_many :teams
  has_many :cards, as: :cardholder
  has_one :deck

  def self.open( user, game_options: {}, team_options: {} )
    game = self.create( game_options )
    team_amount ||= game.team_amount
    teams = game.teams
    team_amount.times do
      teams.create( team_options )
    end
    game.deck = Deck.create
    game.join_with( user, teams[0] )
  end

  def join_with( user, team )
    if team.position_available?
      user.players << team.players.create
    end
    self
  end
end
