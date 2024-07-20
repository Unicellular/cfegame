require 'rails_helper'

RSpec.describe PlayersController, type: :controller do
  describe("get take") do
    it "returns player's new hands" do
      @game = Game.open(User.create)
      @game.join_with(User.create, @game.teams[1])
      @player1 = @game.players[0]
      @game.begin(@player1)
      @player1.annex["take"] = {"amount" => 1, "of" => @player1.look(1, 2)}
      @player1.save
      get :take, params: { game_id: @game.id, id: @player1.id }
      expect(response).to have_http_status(:success)
    end
  end
end
