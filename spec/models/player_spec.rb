require 'rails_helper'

RSpec.describe Player, type: :model do
  before(:each) do
    # 共用變數
    @game = Game.open( User.create )
    @game.join_with( User.create, @game.teams[1] )
    @game.begin( @game.players[0] )
    @player1 = @game.players[0]
    @player2 = @game.players[1]
  end

  context "when player1 perform secret formation" do
    before(:each) do
      player_perform_rule(@player1, "defense", [[:tree, 1], [:tree, 2]])
      @game.turn_end
      @player1.reload
      @game.reload
      @info_form_p1 = @player1.info(true)
      @info_form_p2 = @player1.info(false)
    end

    it "info should show which passive formation player perform from player1's viewpoint" do
      expect(@info_form_p1[:last_acts][0][:rule_name]).to eq("防禦")
    end

    it "info should show nothing from player2's viewpoint" do
      expect(@info_form_p2[:last_acts][0][:rule_name]).to be_nil
    end

    it "info should reveal what player1 do after player2's action" do
      player_perform_rule(@player2, "metal attack", [[:metal, 3]])
      @info_form_p2 = @player1.reload.info(false)
      expect(@info_form_p2[:last_acts][0][:rule_name]).to eq("防禦")
    end
  end

  context "when a player draw cards" do
    before(:each) do
      # 清空手牌
      @game.deck.cards << @player1.cards
      @game.current_turn.draw!
    end

    it "should not have draw_extra effect after discard" do
      @player1.annex["draw_extra"] = 2
      @player1.save
      drawed_cards = @player1.draw(2)
      @player1.discard(2, drawed_cards[0])
      @player1.reload
      expect(@player1.cards.count).to eq(4)
      expect(@player1.annex["draw_extra"]).to be_nil
    end

    it "should not show any cards when draw 0 card" do
      drawed_cards = @player1.draw(0)
      expect(drawed_cards.empty?).to be true
      discard = @player1.discard(0, drawed_cards[0])
      expect(discard).to be_nil
      expect(@player1.is_phase?(:end)).to be true
    end

    it "should not draw none effect atter discard" do
      @player1.annex["draw"] = "none"
      @player1.save
      drawed_cards = @player1.draw(2)
      @player1.discard(2, drawed_cards[0])
      expect(@player1.annex["draw"]).to be_nil
    end

    it "should not keep take effect after discard" do
      drawed_cards = @player1.draw(2)
      # discard should add take effect
      @player1.discard(2, drawed_cards[0])
      expect(@player1.annex["take"]).to be_nil
    end

    it "should not keep take effect even drawing too many cards" do
      drawed_cards = @player1.draw(6)
      # discard should add take effect
      @player1.discard(6, drawed_cards[0])
      expect(@player1.annex["take"]).to be_nil
    end
  end

  it "should change the field after summon tree field" do
    @player1.summon({"field" => "tree"})
    @game.reload
    expect(@game.field).to eq("tree")
  end

  context "when player obtain a card" do
    before(:each) do
      # todo
    end

    it "should get a virtual card with the modified value #1" do
      old_card = [Card.new(element: :fire, level: 1)]
      @player1.obtain(old_card, element: :earth)
      @player1.reload
      expect(@player1.cards.where(element: "earth", level: 1, virtual: true).count).to eq(1)
    end

    it "should get a virtual card with the modified value #2" do
      old_card = [Card.new(element: :fire, level: 1)]
      @player1.obtain(old_card, level: 4)
      @player1.reload
      expect(@player1.cards.where(element: "fire", level: 4, virtual: true).count).to eq(1)
    end

    it "should get a virtual card with the modified value when using random 2 cards" do
      old_card = [Card.new(element: :water, level: 5), Card.new(element: :earth, level: 3)]
      @player1.obtain(old_card, element: :fire, level: 2)
      @player1.reload
      expect(@player1.cards.where(element: "fire", level: 2, virtual: true).count).to eq(1)
    end
  end

  context "when a player craft a card" do
    before(:each) do
      @game.current_turn.events.create(player: @player1, cards_used: [{element: :fire, level: 1}], effect: {}, rule: Rule.find_by_name("craft"))
      @player1.attached(craft: "card")
      @player1.craft(element: :water, level: 3)
    end

    it "should get a virtual card with the modified value" do
      expect(@player1.cards.where(element: "water", level: 3, virtual: true).count).to eq(1)
    end

    it "should modified the event causing this crafting effect" do
      event = @game.current_turn.events.joins(:rule).where(rules: {form: :power, subform: :active}).order(created_at: :desc).first
      expect(event.effect["crafted"]["element"]).to eq("water")
      expect(event.effect["crafted"]["level"]).to eq(3)
      expect(event.effect["crafted"]["virtual"]).to eq(true)
      expect(event.effect["point"]).to eq(-3)
    end
  end

  context "put some of hands on top of deck" do
    before(:each) do
      @player1.attached({"remove": {"amount": 2, "to": "deck"}, "showhand": true})
    end

    context "target has more than 2 cards" do
      before(:each) do
        @player1_hands = get_cards([[:metal, 1], [:tree, 2], [:water, 3]])
        @player1.cards = @player1_hands
        @player1.save
      end

      context "when be removed 2 cards" do
        before(:each) do
          @player1.removed(@player1_hands[1..2], @player1)
        end

        it "should lose 2 cards" do
          expect(@player1.reload.cards).to contain_exactly(@player1_hands[0])
        end

        it "should put removed cards on the top of the deck" do
          expect(@game.deck.reload.cards[0..1]).to match_array(@player1_hands[1..2])
        end

        it "should delete remove annex" do
          expect(@player1.annex["remove"]).to be_falsy
        end
      end
    end

    context "target has only 1 cards" do
      before(:each) do
        @player1_hands = get_cards([[:water, 3]])
        @player1.cards = @player1_hands
        @player1.save
      end

      context "player2 select 1 cards to remove" do
        before(:each) do
          @game.turn_end
          @player2.set_phase(:action)
          @player2.select(@player1, @player1_hands)
        end

        it "should remove the card" do
          expect(@player1.reload.cards).to be_empty
        end

        it "should delete remove annex" do
          expect(@player1.annex["remove"]).to be_falsy
        end
      end

      it "should raise exception when be removed 2 cards" do
        expect {
          @player1.removed(@player1_hands + get_cards([[:tree, 2]]), @player1)
        }.to raise_exception("the cards of target 1 is not removable.")
        expect(@player1.reload.cards).to contain_exactly(@player1_hands[0])
        expect(@game.deck.reload.cards[0,1]).not_to contain_exactly(@player1_hands[0])
        expect(@player1.annex["remove"]["amount"]).to eq(2)
        expect(@player1.annex["showhand"]).to be_truthy
      end
    end
  end

  context "after viewing target's hand" do
    before(:each) do
      @player2.attached({"freeze": 2, "showhand": true})
      @player1.set_phase(:action)
      @player1.select(@player2, [])
    end

    it "should delete the showhand effect" do
      expect(@player2.reload.annex["showhand"]).to be_falsy
    end
  end

  context "player take more than 1 cards" do
    before(:each) do
      @player1.annex["take"] = {"amount" => 1, "of" => @player1.look(1, 3)}
      @player1.cards = get_cards([[:fire, 1]])
      @look_cards = @player1.look(1, 3)
    end

    it "should raise exception" do
      expect {
        @player1.take(@look_cards, @look_cards[1..2])
      }.to raise_exception("the amount of taking cards is wrong")
    end
  end
end
