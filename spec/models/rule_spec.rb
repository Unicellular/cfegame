require 'rails_helper'

RSpec.describe Rule, type: :model do
  before( :each ) do
    @card = Card.create!( element: :metal, level: 3 )
    @rule = Rule.find_by_name( "金擊術" )
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.begin( @game.players[0] )
  end

  it "calculates right point" do
    expect( @rule.calculate( [ @card ] ) ).to eq( 7 )
  end

  it "should pass the test" do
    expect( @rule.test( [ @card ] ) ).to eq( true )
  end

  it "should attack right target with right amount of damage" do
    p1 = @game.players[0]
    p2 = @game.players[1]
    p1.perform( @rule, [ @card ] )
    expect( p2.team.life ).to eq( 193 )
  end

  it "should write what the performer did in current turn" do
    p1 = @game.players[0]
    p1.perform( @rule, [ @card ] )
    turn = @game.current_turn
    target = @rule.get_target( p1, @game )
    test_feature = {
      players: { id: p1 },
      cards: { id: [ @card ] }
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
end
