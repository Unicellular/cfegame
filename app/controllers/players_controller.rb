class PlayersController < ApplicationController
  before_action :must_be_my_turn

  def turn_end
    #@game = Game.find(params[:gid])
    @game.turn_end
  end

  def use_cards
    #@player = Player.find(params[:pid])
    puts (params[:cards].map{|i, c| c['id'] })
    cards_used = @player.using( params[:cards].map{|i, c| c['id'] } )
    render json: { hands: @player.hands(true), cards_used: cards_used }
  end

  def draw
    #@player = Player.find(params[:pid])
    render json: @player.draw(2)
  end

  def discard
    #@player = Player.find(params[:pid])
    @discard = Card.find(params[:card_id])
    discard = @player.discard(2, @discard)
    render json: { hands: @player.hands(true), discard: discard }
  end

  private

  # player must be in his turn at that game.
  def must_be_my_turn
    @game = Game.find(params[:gid])
    @player = Player.find(params[:pid])
    unless @game.turn_player == @player
      render status: :forbidden
    end
  end
end
