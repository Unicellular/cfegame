require 'rails_helper'

RSpec.describe Player, type: :model do
  before( :each ) do
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.begin( @game.players[0] )
    @player1 = @game.players[0]
    @player2 = @game.players[1]
    @two_trees = @game.deck.find_card( :tree, 2 ).first(2)
    @another_metal = [ @game.deck.find_card( :metal, 4 ).first ]
    @player1.cards << @two_trees
    @player2.cards << @another_metal
    @defense = Rule.find_by_name( "defense" )
    @metal_attack = Rule.find_by_name( "metal attack" )
    @player1.perform( @defense, @two_trees )
    @player1.turn_end
    @info_form_p1 = @player1.info( true )
    @info_form_p2 = @player1.info( false )
  end

  it "info should show which passive formation player perform from player1's viewpoint" do
    expect( @info_form_p1[:last_acts][0][:rule_name] ).to eq( "防禦" )
  end

  it "info should show nothing from player2's viewpoint" do
    expect( @info_form_p2[:last_acts][0][:rule_name] ).to be_nil
  end

  it "info should reveal what player1 do after player2's action" do
    @player2.perform( @metal_attack, @another_metal )
    @info_form_p2 = @player1.info( false )
    expect( @info_form_p2[:last_acts][0][:rule_name] ).to eq( "防禦" )
  end
end
