class PlayersController < ApplicationController
  def turn_end
    @game = Game.find(params[:game_id])
    @game.turn_end
  end

  def use_cards
    @player = Player.find(params[:player_id])
    puts (params[:cards].map{|i, c| c['id'] })
    cards_used = @player.using( params[:cards].map{|i, c| c['id'] } )
    render json: { hands: @player.hands(true), cards_used: cards_used }
  end

  def draw
    @player = Player.find(params[:player_id])
    render json: @player.draw(2)
  end

  def discard
    @player = Player.find(params[:player_id])
    @discard = Card.find(params[:card_id])
    discard = @player.discard(2, @discard)
    render json: { hands: @player.hands(true), discard: discard }
  end
end
