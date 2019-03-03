class Game < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :players, -> { order(:sequence) }, through: :teams
  has_many :cards, as: :cardholder, dependent: :destroy
  has_many :turns, -> { order(:number) }, dependent: :destroy
  has_one :deck, dependent: :destroy

  enum status: [ :prepare, :start, :over ]

  def self.open( user, game_options: {}, team_options: {} )
    game = self.create!( game_options )
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
      generate_turn
    end

    info( player )
  end

  def reinit
    deck.cards << players[0].cards << players[1].cards
    deck.shuffle
    #update( turn: 0 )
    prepare!
    turns.destroy_all
  end

  def info( player )
    game_status = as_json({
      except: [ :created_at, :updated_at ]
    })
    game_status[:myturn] = ( turn_player == player )
    game_status[:discard] = cards.where( position: -1 ).first
    game_status[:winning] = ( teams.index( player.team ) == winner )
    teams.each do |team|
      if team.players.include? player
        game_status[:current] = team.info(player)
      else
        game_status[:opponent] = team.info(player)
      end
    end
    game_status.merge( { possible_moves: [], choices: [] } )
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
    players[ ( first + turn ) % players.count ]
  end

  def last_player
    players[ ( first + turn - 1 ) % players.count ]
  end

  def turn_end
    increment!(:turn)
    generate_turn
  end

  def generate_turn
    turns.create number: turn
  end

  def current_turn
    turns[turn]
  end

  def last_turn
    turns[turn-1]
  end

  def draw_amount
    2
  end

  def exchange
    temp = teams[0].life
    teams[0].update( life: teams[1].life )
    teams[1].update( life: temp )
  end

  def trigger( player )
    3.times do
      trigger_rules = Rule.all_fitted( self, player )
      trigger_rules.each do |rule|
        rule.performed( player, [], self, turn )
      end
    end
  end

  def check_over
    winners = teams.select do |team|
      team.life > 0
    end
    #byebug
    if winners.count <= 1
      decide_winner( winners.first )
    end
    #save
  end

  def decide_winner( team )
    unless team.nil?
      update!( winner: teams.index( team ) )
      over!
    end
  end

  def eject( entity )
    effected = []
    entity.each do |key, value|
      case key
      when "star"
        teams.each do |team|
          if team.has_star?( value ) || ( value == "all" && team.star != :nothing )
            team.star = :nothing
            effected.push( team )
          end
          team.save
        end
      end
    end
    effected
  end

  def discarded( card )
    ActiveRecord::Base.transaction do
      last_discard = cards.where( position: -1 ).first
      last_discard.update( position: card.position ) unless last_discard.nil?
      card.update( position: -1 )
      cards << card
    end
  end
end
