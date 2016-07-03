class GameController < ApplicationController
  def index
    game = Game.find(params[:gid])
    player = Player.find(params[:pid])
    if game.ready?
      render json: game.begin(player)
    else
      render json: false
    end
  end

  def status
    game = Game.find(params[:gid])
    player = Player.find(params[:pid])
    render json: game.status(player)
  end
end
