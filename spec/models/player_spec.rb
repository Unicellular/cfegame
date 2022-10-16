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

  it "should not have draw_extra effect after discard" do
    # 清空手牌
    @game.deck.cards << @player1.cards
    @game.current_turn.draw!
    @player1.annex["draw_extra"] = 2
    @player1.save
    drawed_cards = @player1.draw(2)
    dishand = @player1.discard(2, drawed_cards[0])
    @player1.reload
    expect(@player1.cards.count).to eq(4)
    expect(@player1.annex["draw_extra"]).to be_nil
  end

  it "shold change the field after summon tree field" do
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
end
