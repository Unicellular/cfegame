class Game < ApplicationRecord
  has_many :teams, dependent: :destroy
  has_many :players, -> { order(:sequence) }, through: :teams
  has_many :cards, as: :cardholder, dependent: :destroy
  has_many :turns, -> { order(:number) }, dependent: :destroy
  has_one :deck, dependent: :destroy

  enum status: [ :prepare, :start, :over ]
  enum field: { nothing: 0, metal: 1, tree: 2, water: 3, fire: 4, earth: 5 }

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
      # 不加這行測試會報錯
      deck.reload
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
      trigger_rules = Rule.all_fitted( self, player, :passive )
      trigger_rules.each do |rule|
        rule.performed( player, [], self )
      end
    end
  end

  def trigger_continuous_effect
    players.each do |player|
      Rule.where( form: :power, subform: :continuous ).each do |rule|
        rule.performed(player, [], self)
      end
    end
  end

  def check_over
    winners = teams.select do |team|
      team.life > 0
    end
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

  def eject(entity, rank)
    effected = []
    entity.each do |key, value|
      case key
      when "star"
        teams.each do |team|
          if team.has_star?(value) || (value == "all" && !team.has_star?("nothing"))
            team.star = :nothing
            effected.push( team )
          end
          team.save
        end
      when "field"
        effected = (teams.to_a) unless nothing?
        nothing!
      when "hero"
        players.each do |player|
          if rank >= 3 || !player.lengendary?
            player.deleted("hero")
          end
        end
      end
    end
    save
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

  def event_list(viewer)
    turns.reverse.map do |turn|
      {
        turn: turn.number,
        events: turn.events.left_outer_joins(:rule).map { |event|
          rule_name = event.rule ? event.rule.name : nil
          if event.player != viewer && event.rule&.passive? && event.player.annex["hidden"] == "counter"
            {cards_used: event.cards_used.count}
          else
            {cards_used: event.cards_used.map{|c| c.to_hash}, rule: rule_name, effect: event.effect}
          end
        }
      }
    end
  end
end
