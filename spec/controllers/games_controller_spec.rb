require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  describe "GET 'game'" do
    it "returns http success" do
      @user = User.create
      @game = Game.open(@user)
      get :show, params: { id: @game.id }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET event_list" do
    before(:each) do
      @user1 = User.create
      @user2 = User.create
      @game = Game.open(@user1)
      @game.join_with(@user2, @game.teams[1])
      @player1 = @game.players.find_by(user: @user1)
      @player2 = @game.players.find_by(user: @user2)
      session[:user_id] = @user1.id
      @game.begin(@player1)
    end

    it "forbids with wrong player" do
      get :event_list, params: { game_id: @game.id, id: @player2.id }
      expect(response).to have_http_status(:forbidden)
    end

    it "shows the event list of current player" do
      get :event_list, params: { game_id: @game.id, id: @player1.id }
      expect(response).to have_http_status(:ok)
      ev_list = JSON.parse(response.body)
      expect(ev_list).to eq([{"player" => @player1.id, "number" => 0, "events" => []}])
    end
  end
end
