class HomeController < ApplicationController
  def lobby
    @games = Game.all
  end

  def open
    if user_signed_in?
      @game = Game.open current_user
      redirect_to game_path(@game)
    else
      redirect_to signin_path
    end
  end

  def join
    @game = Game.find(params[:id])
    @team = Team.find(params[:team_id])
    if @game && user_signed_in?
      @game.join_with current_user, @team
      redirect_to game_path(@game)
    else
      redirect_to signin_path
    end
  end

  def game
    @game = Game.find(params[:id])
    @player = current_player(@game)
    @opponent = @game.players[@player.sequence+1]
  end
end
