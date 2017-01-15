require 'rails_helper'

RSpec.describe Rule, type: :model do
  before( :each ) do
    @gattack = Rule.find_by_name( "metal attack" )
    @defense = Rule.find_by_name( "defense" )
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.begin( @game.players[0] )
    @onemetal = [ @game.deck.find_card( :metal, 3 ).first ]
    @twotrees = @game.deck.find_card( :tree, 2 ).first(2)
    @player1 = @game.players[0]
    @player2 = @game.players[1]
    @player1.cards << @onemetal << @twotrees
  end

  it "calculates right point" do
    expect( @gattack.calculate( @onemetal ) ).to eq( 7 )
  end

  it "should pass the test" do
    expect( @gattack.test( @onemetal ) ).to eq( true )
  end

  it "should attack right target with right amount of damage" do
    @player1.perform( @gattack, @onemetal )
    expect( @player2.team.life ).to eq( 193 )
  end

  it "should write what the performer did in current turn" do
    @player1.perform( @gattack, @onemetal )
    turn = @game.current_turn
    target = @gattack.get_target( @player1, @game )
    test_feature = {
      player: @player1,
      target: target
    }
    test_effect = [ {
      "to" => target.id,
      "content" => { "attack" => [ "metal", 7 ] }
    } ]
    cards_used = @onemetal.map { |c| c.to_hash }
    event = turn.events.where( test_feature ).take
    expect( event.cards_used ).to eq( cards_used )
    expect( event.effect ).to eq( test_effect )
  end

  context "when player perform defense" do
    it "should counter opponent's attack at next turn" do
      @player1.perform( @defense, @twotrees )
      @game.turn_end
      @player2.perform( @gattack, @onemetal )
      expect( @player1.team.life ).to eq( @player1.team.life_limit )
    end
  end
end
