class GameController < ApplicationController
  include ActionController::Live
  def index
    game = Game.find(params[:id])
    player = Player.find(params[:player_id])
    if game.ready?
      render json: game.start(player)
    else
      render json: false
    end
  end
end
