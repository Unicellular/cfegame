require 'rails_helper'

RSpec.describe Rule, type: :model do
  before( :each ) do
    @onemetal = [ Card.create!( element: :metal, level: 3 ) ]
    @twotrees = [ Card.create!( element: :tree, level: 2), Card.create!( element: :tree, level: 2) ]
    @gattack = Rule.find_by_name( "metal attack" )
    @defense = Rule.find_by_name( "defense" )
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.begin( @game.players[0] )
  end

  it "calculates right point" do
    expect( @gattack.calculate( @onemetal ) ).to eq( 7 )
  end

  it "should pass the test" do
    expect( @gattack.test( @onemetal ) ).to eq( true )
  end

  it "should attack right target with right amount of damage" do
    p1 = @game.players[0]
    p2 = @game.players[1]
    p1.perform( @gattack, @onemetal )
    expect( p2.team.life ).to eq( 193 )
  end

  it "should write what the performer did in current turn" do
    p1 = @game.players[0]
    p1.perform( @gattack, @onemetal )
    turn = @game.current_turn
    target = @gattack.get_target( p1, @game )
    test_feature = {
      players: { id: p1 },
      cards: { id: @onemetal }
    }
    test_effect = {
      "target" => target.id,
      "content" => { "attack" => [ "metal", 7 ] }
    }
    effects = turn.events.joins( :player, :cards ).where( test_feature ).map do |e|
      e.effect
    end
    expect( effects ).to include( test_effect )
  end

  context "when player perform defense" do
    it "should counter opponent's attack at next turn" do
      p1 = @game.players[0]
      p2 = @game.players[1]
      p1.perform( @defense, @twotrees )
      @game.turn_end
      p2.perform( @gattack, @onemetal )
      expect( p1.team.life ).to eq( p1.team.life_limit )
    end
  end
end
