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

  context "when game trigger continuous effect" do
    before(:each) do
      @game.players[0].annex["hero"] = ["brave", "mars", "warrior"]
      @game.players[1].annex["fire_resistance"] = {"fire"=> "none"}
      @game.trigger_continuous_effect
    end

    it "should give player1 metal resistance" do
      expect(@game.players[0].annex).to include({"metal_resistance"=> {"metal"=> "none"}})
    end

    it "should record a event in the current turn for the adding activity" do
      effect = {"gain"=> {"metal_resistance"=> {"metal"=> "none"}}, "affected_way"=> "gain"}
      expect(@game.current_turn.events.where(player: @game.players[0], rule: Rule.find_by_name("metal resistance")).first.effect).to include(effect)
    end

    it "should remove player2's fire resistance" do
      expect(@game.players[1].annex).not_to include("fire_resistance")
    end

    it "should record a event in the current turn for the removing activity" do
      effect = {"gain"=> {"fire_resistance"=> {"fire"=> "none"}}, "affected_way"=> "remove"}
      expect(@game.current_turn.events.where(player: @game.players[1], rule: Rule.find_by_name("fire resistance")).first.effect).to include(effect)
    end

    it "should not record a event for other unrelated rule" do
      expect(@game.current_turn.events.where(rule: Rule.find_by_name("tree resistance")).count).to eq(0)
    end
  end
end
