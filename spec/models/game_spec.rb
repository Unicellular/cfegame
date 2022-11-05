require 'rails_helper'

RSpec.describe Game, type: :model do
  before(:each) do
    @game = Game.open(User.create)
    @game.join_with(User.create, @game.teams[1])
    @game.begin(@game.players[0])
  end

  context "when a game started" do
    it "should set the turn number to 0" do
      expect(@game.turn).to eq(0)
    end

    it "should increment the turn number when turn ended" do
      @game.turn_end
      expect(@game.reload.turn).to eq(1)
      @game.turn_end
      expect(@game.reload.turn).to eq(2)
    end
  
    it "should set the status of the game to :start" do
      expect(@game.start?).to eq(true)
    end
  
    it "should deal cards to each player" do
      player1 = @game.players[0]
      player2 = @game.players[1]
      expect(player2.reload.cards.count).to eq(5)
      expect(player1.reload.cards.count).to eq(5)
    end
  end

  it "should exchange two teams' life after excahnging" do
    @game.teams[0].update(life: 50)
    @game.teams[1].update(life: 150)
    @game.exchange
    @game.reload
    expect(@game.teams[0].life).to eq(150)
    expect(@game.teams[1].life).to eq(50)
  end
end
