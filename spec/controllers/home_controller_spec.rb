require 'spec_helper'

describe HomeController do

  describe "GET 'game'" do
    it "returns http success" do
      @game = Game.create
      get :game, id: @game.id
      expect(response).to have_http_status(:success)
    end
  end

end
