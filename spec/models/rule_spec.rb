require 'rails_helper'

RSpec.describe Rule, type: :model do
  before( :each ) do
    @card = Card.create!( element: :metal, level: 3 )
    @rule = Rule.find_by_name( "金擊術" )
  end

  it "calculates right point" do
    expect( @rule.calculate( [ @card ] ) ).to eq( 7 )
  end

  it "should pass the test" do
    expect( @rule.test( [ @card ] ) ).to eq( true )
  end

  it "should attack right target with right amount of damage" do
    game = Game.open( User.new )
    game.join_with( User.new, game.teams[1] )
    p1 = game.players[0]
    p2 = game.players[1]
    p1.perform( @rule, [ @card ] )
    expect( p2.team.life ).to eq( 193 )
  end
end
