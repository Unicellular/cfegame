class TeamsController < ApplicationController
  def join
    @game = Game.find(params[:game_id])
    @team = Team.find(params[:id])
    if @game && user_signed_in?
      @game.join_with current_user, @team
      redirect_to game_path(@game)
    else
      redirect_to signin_path
    end
  end
end
