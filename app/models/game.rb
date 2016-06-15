class Game < ActiveRecord::Base
  has_many :teams, dependent: :destroy
  has_many :players, -> { order(:sequence) }, through: :teams
  has_many :cards, as: :cardholder, dependent: :destroy
  has_one :deck, dependent: :destroy

  enum status: [ :prepare, :start, :over ]

  def self.open( user, game_options: {}, team_options: {} )
    game = self.create( game_options )
    team_amount ||= game.team_amount
    teams = game.teams
    team_amount.times do
      teams.create( team_options )
    end
    game.deck = Deck.new
    game.deck.shuffle true
    game.join_with( user, teams[0] )
  end

  def join_with( user, team )
    if team.position_available?
      team_index = teams.find_index team
      sequence = team_index + teams.count * team.players.count
      player = team.players.create sequence: sequence
      user.players << player
    end
    self
  end

  def ready?
    teams.all? do |team|
      !(team.position_available?)
    end
  end

  def begin( player )
    if prepare?
      deal_cards
      start!
    end

    Hash[teams.map { |team|
      if team.players.include? player
        [:current, team.info(player)]
      else
        [:opponent, team.info(player)]
      end
    }]
  end

  def deal_cards
    players.each do |player|
      player.cards << deck.cards.first(player.hand_limit)
    end
  end

  def opponent_team( player )
    teams.where.not(id: player.team)
  end

  def turn_player
    @turn_player || players[first+turn]
  end

  def turn_end
    turn = turn + 1
  end
end
