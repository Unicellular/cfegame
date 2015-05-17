class HomeController < ApplicationController
  def lobby
    @games = Game.all
  end

  def open
    @game = Game.open current_user if user_signed_in?
    redirect_to root_path
  end

  def join
    @game = Game.find(params[:id])
    @team = Team.find(params[:team_id])
    @game.join_with current_user, @team if @game && user_signed_in?
    redirect_to root_path
  end
end
