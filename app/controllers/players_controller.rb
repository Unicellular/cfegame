class PlayersController < ApplicationController
  before_action :must_be_my_turn
  after_action :if_game_end
  skip_before_action :must_be_my_turn, only: [ :find_opponent, :info ]
  skip_after_action :if_game_end, only: [ :find_opponent, :info, :possible_moves ]

  def find_opponent
    game = Game.find(params[:game_id])
    player = Player.find(params[:id])
    if game.ready?
      render json: game.begin(player)
    else
      render json: false
    end
  end

  def info
    game = Game.find(params[:game_id])
    player = Player.find(params[:id])
    render json: game.info(player)
  end

  def turn_end
    @player.turn_end
    @game.reload
    @game.turn_player.turn_start
    render json: @game.info(@player)
  end

  def use_cards
    puts (params[:cards].map{|i, c| c['id'] })
    cards_used = @player.using( params[:cards].map{|i, c| c['id'] } )
    render json: { hands: @player.hands(true), cards_used: cards_used }
  end

  def draw
    render json: @player.draw( @game.draw_amount )
  end

  def discard
    @discard = Card.find(params[:cards] || [])
    discard = @player.discard( @game.draw_amount, @discard )
    render json: { hands: @player.hands(true), discard: discard }
  end

  def recycle
    @discard = Card.find(params[:cards] || [])
    @player.recycle( @discard )
    render json: @game.reload.info(@player)
  end

  def possible_moves
    cards = Card.find(params[:cards] || [])
    rules = Rule.action.or(Rule.active_power).select do |rule|
      rule.total_test( cards, @game, @player )
    end
    render json: rules.map { |rule| { id: rule.id, name: rule.chinese_name } }
  end

  def perform
    cards = Card.find(params[:cards] || [])
    rule = Rule.find(params[:rule])
    @player.perform( rule, cards )
    render json: @game.reload.info(@player)
  end

  def select
    target = Player.find(params[:opponent])
    cards = Card.find(params[:cards] || [])
    @player.select( target, cards )
    render json: @game.reload.info(@player)
  end

  def craft
    crafted = {element: params[:element], level: params[:level]}
    @player.craft(crafted)
    render json: @game.reload.info(@player)
  end

  def take
    looked_cards = @player.annex["take"]["of"]
    selecteds = Card.find(params[:cards] || [])
    render json: @player.take(looked_cards, looked_cards - selecteds)
  end

  private

  # player must be in his turn at that game.
  def must_be_my_turn
    @game = Game.find(params[:game_id])
    @player = Player.find(params[:id])
    unless @game.turn_player == @player
      render nothing: true, status: :forbidden
    end
  end

  def if_game_end
    #@game.trigger( @player )
    @game.trigger_continuous_effect
    @game.check_over
  end
end
