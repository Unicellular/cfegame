require 'rails_helper'

RSpec.describe Game, type: :model do
  it "should increment the turn number when turn ended" do
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    expect( @game.turn ).to eq(0)
    @game.begin( @game.players[0] )
    expect( @game.reload.turn ).to eq(0)
    @game.turn_end
    expect( @game.reload.turn ).to eq(1)
    @game.turn_end
    expect( @game.reload.turn ).to eq(2)
  end

  it "should exchange two teams' life after excahnging" do
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.teams[0].update( life: 50 )
    @game.teams[1].update( life: 150 )
    @game.exchange
    @game.reload
    expect( @game.teams[0].life ).to eq( 150 )
    expect( @game.teams[1].life ).to eq( 50 )
  end
end
