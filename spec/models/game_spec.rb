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

  context "when game export a list of events" do
    it "should return a list of one turn" do
      expect(@game.event_list(@game.players[0]).count).to eq(1)
    end

    it "should return a list that contained an empty turn" do
      expect(@game.event_list(@game.players[0])[0]).to eq({turn: {player: @game.players[0].id, number: @game.turn}, events: []})
    end

    context "when there are serveral events happened" do
      before(:each) do
        @dishand = []
        @player1 = @game.players[0]
        @player2 = @game.players[1]
        player_perform_rule(@player1, "metal attack", [[:metal, 3]])
        drawed = @player1.draw(2)
        @dishand.push(@player1.discard(2, drawed[0]))
        @player1.turn_end
        player_perform_rule(@player2, "fire attack", [[:fire, 4]])
        drawed = @player2.draw(2)
        @dishand.push(@player2.discard(2, drawed[0]))
        @game.reload
      end

      it "the first item on the list should be the newest turn" do
        event_list = @game.event_list(@player1)
        expect(event_list[0][:turn]).to eq({player: @player2.id, number: @game.turn})
      end

      it "the first item on the list should contain latest action" do
        event_list = @game.event_list(@player1)
        expect(event_list[0][:events][0]).to include(cards_used: [{"element" => "fire", "level" => 4}], rule: "fire attack", effect: {"point" => 8, "attack" => 8, "modified_point" => 8})
        expect(event_list[0][:events][1]).to include(effect: {"take" => 2, "discard" => [@dishand[1].to_hash]})
      end

      context "when secret event happend" do
        before(:each) do
          @player2.turn_end
          @game.reload
          @player1.reload
          player_perform_rule(@player1, "defense", [[:tree, 1], [:tree, 2]])
          drawed = @player1.draw(2)
          @dishand.push(@player1.discard(2, drawed[0]))
          @player1.turn_end
          @game.reload
        end

        it "should only show the number of cards used" do
          event_list = @game.event_list(@player2)
          expect(event_list[1][:events][0]).to include(cards_used: 2)
        end

        it "should the owner of last turn is oppoenet" do
          event_list = @game.event_list(@player2)
          expect(event_list[1][:turn][:player]).to eq(@player1.id)
        end

        context "after player 2 performing action" do
          before(:each) do
            @player2.reload
            player_perform_rule(@player2, "weapon", [[:metal, 4], [:metal, 3]])
            drawed = @player2.draw(2)
            @dishand.push(@player2.discard(2, drawed[0]))
            @game.reload
          end

          it "should show the detail of secret event" do
            expect(@game.event_list(@player2)[1][:events][0]).to include(cards_used: [{"element" => "tree", "level" => 1}, {"element" => "tree", "level" => 2}], rule: "defense")
          end
        end
      end
    end
  end
end
