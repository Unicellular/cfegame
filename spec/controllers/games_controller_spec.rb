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
end
