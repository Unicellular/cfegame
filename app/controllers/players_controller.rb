class PlayersController < ApplicationController
  before_action :must_be_my_turn

  def turn_end
    #@game = Game.find(params[:gid])
    @game.turn_end
    render nothing: true
  end

  def use_cards
    #@player = Player.find(params[:pid])
    puts (params[:cards].map{|i, c| c['id'] })
    cards_used = @player.using( params[:cards].map{|i, c| c['id'] } )
    render json: { hands: @player.hands(true), cards_used: cards_used }
  end

  def draw
    #@player = Player.find(params[:pid])
    render json: @player.draw(params[:amount].to_i)
  end

  def discard
    #@player = Player.find(params[:pid])
    @discard = Card.find(params[:card_id])
    discard = @player.discard(params[:amount].to_i, @discard)
    render json: { hands: @player.hands(true), discard: discard }
  end

  def recycle
    @discard = Card.find(params[:card_id])
    @deck = @game.deck
    @deck.recycle( @discard )
    render nothing: true
  end

  def possible_moves
    cards = Card.find(params[:cards] || [])
    rules = Rule.all.select do |rule|
      rule.test( cards )
    end
    render json: rules.map { |rule| { id: rule.id, name: rule.chinese_name } }
  end

  def perform
    cards = Card.find(params[:cards] || [])
    rule = Rule.find(params[:rule_id])
    @player.perform( rule, cards )
    render json: @game.info(@player)
  end

  private

  # player must be in his turn at that game.
  def must_be_my_turn
    @game = Game.find(params[:gid])
    @player = Player.find(params[:pid])
    unless @game.turn_player == @player
      render nothing: true, status: :forbidden
    end
  end
end
