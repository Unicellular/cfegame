require 'spec_helper'

describe HomeController do

  describe "GET 'game'" do
    it "returns http success" do
      @game = Game.create
      get :game, id: @game.id
      response.should be_success
    end
  end

end
