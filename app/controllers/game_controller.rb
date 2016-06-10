class GameController < ApplicationController
  def index
    game = Game.find(params[:id])
    player = current_player(game)
    if game.ready?
      render json: game.begin(player)
    else
      render json: false
    end
  end
end
