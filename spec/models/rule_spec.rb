require 'rails_helper'

RSpec.describe Rule, type: :model do
  before( :each ) do
    @gattack = Rule.find_by_name( "metal attack" )
    @defense = Rule.find_by_name( "defense" )
    @imitate = Rule.find_by_name( "imitate" )
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.begin( @game.players[0] )
    @one_metal = [ @game.deck.find_card( :metal, 3 ).first ]
    @another_metal = [ @game.deck.find_card( :metal, 4 ).first ]
    @one_tree = [ @game.deck.find_card( :tree, 1 ).first ]
    @two_trees = @game.deck.find_card( :tree, 2 ).first(2)
    @two_earthes = @game.deck.find_card( :earth, 4 ).first(2)
    @player1 = @game.players[0]
    @player2 = @game.players[1]
    @player1.cards << @one_metal << @two_trees
    @player2.cards << @two_earthes << @another_metal << @one_tree
  end

  it "calculates right point" do
    expect( @gattack.calculate( @one_metal ) ).to eq( 7 )
  end

  it "should pass the test" do
    expect( @gattack.test( @one_metal ) ).to eq( true )
  end

  it "should attack right target with right amount of damage" do
    @player1.perform( @gattack, @one_metal )
    expect( @player2.team.life ).to eq( 193 )
  end

  it "should write what the performer did in current turn" do
    @player1.perform( @gattack, @one_metal )
    turn = @game.current_turn
    target = @gattack.get_target( @player1, @game )
    test_feature = {
      player: @player1,
      target: target,
      rule: @gattack
    }
    test_effect = [ {
      "to" => target.id,
      "content" => { "attack" => [ "metal", 7 ] }
    } ]
    cards_used = @one_metal.map { |c| c.to_hash }
    event = turn.events.where( test_feature ).take
    expect( event.cards_used ).to eq( cards_used )
    expect( event.effect ).to eq( test_effect )
  end

  context "when player perform copy" do
    it "should copy what last player do" do
      @player1.perform( @gattack, @one_metal )
      @game.turn_end
      @player2.perform( @imitate, @two_earthes )
      expect( @player2.team.life ).to eq( 193 )
      expect( @player1.reload.team.life ).to eq( 194 )
      expect( @player2.reload.sustained[:element] ).to eq( "metal" )
    end
  end

  context "when player perform defense" do
    it "should counter opponent's attack at next turn" do
      @player1.perform( @defense, @two_trees )
      @game.turn_end
      @player2.perform( @gattack, @one_metal )
      expect( @player1.team.life ).to eq( @player1.team.life_limit )
    end
  end
end
