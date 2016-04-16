class Game < ActiveRecord::Base
  has_many :teams
  has_many :players, through: :teams
  has_many :cards, as: :cardholder
  has_one :deck

  enum status: [ :prepare, :start, :over ]

  def self.open( user, game_options: {}, team_options: {} )
    game = self.create( game_options )
    team_amount ||= game.team_amount
    teams = game.teams
    team_amount.times do
      teams.create( team_options )
    end
    game.deck = Deck.new
    #game.deck.shuffle
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
      player.cards << deck.cards.order(:position).first(player.hand_limit)
    end
  end

  def opponent_team( player )
    teams.where.not(id: player.team)
  end
end
