class GamesController < ApplicationController
  def index
    @games = Game.all
  end

  def show
    @game = Game.find(params[:id])
    @player = current_player(@game)
    #render component: 'GameField', props: @game.info( @player )
  end

  def create
    if user_signed_in?
      @game = Game.open current_user
      redirect_to game_path(@game)
    else
      redirect_to signin_path
    end
  end
end
