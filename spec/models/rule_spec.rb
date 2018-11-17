require 'rails_helper'

RSpec.describe Rule, type: :model do
  before( :each ) do
    @metal_attack = Rule.find_by_name( "metal attack" )
    @tree_attack = Rule.find_by_name( "tree attack" )
    #@defense = Rule.find_by_name( "defense" )
    #@imitate = Rule.find_by_name( "imitate" )
    @generate = Rule.find_by_name( "generating formation")
    @overcome = Rule.find_by_name( "overcoming formation" )
    @feao = Rule.find_by_name( "five element as one" )
    @game = Game.open( User.new )
    @game.join_with( User.new, @game.teams[1] )
    @game.begin( @game.players[0] )
    @player1 = @game.players[0]
    @player2 = @game.players[1]
    @game.deck.cards << @player1.cards << @player2.cards
    @player1.reload
    @player2.reload
    @one_metal = [ @game.deck.find_card( :metal, 3 ).first ]
    @another_metal = [ @game.deck.find_card( :metal, 4 ).first ]
    @one_tree = [ @game.deck.find_card( :tree, 1 ).first ]
    @two_trees = @game.deck.find_card( :tree, 2 ).first(2)
    @two_earthes = @game.deck.find_card( :earth, 4 ).first(2)
    @other_two_earthes = @game.deck.find_card( :earth, 3 ).first(2)
    @two_metal = @game.deck.find_card( :metal, 5 ).first(2)
    @two_other_metal = @game.deck.find_card( :metal, 2 ).first(2)
    @one_earth = @game.deck.find_card( :earth, 5 ).first
    #@player1.cards = [ @one_metal, @two_trees, @other_two_earthes, @two_metal, @two_other_metal, @one_earth ].flatten
    #@player2.cards = [ @two_earthes, @another_metal, @one_tree ].flatten
  end

  it "calculates right point" do
    expect( @metal_attack.calculate( @one_metal ) ).to eq( 7 )
  end

  it "should pass the test" do
    expect( @metal_attack.combination_test( @one_metal ) ).to eq( true )
  end

  it "should pass the advanced test" do
    cards_tested = [ Card.new( element: :metal, level: 1 ), Card.new( element: :water, level: 5 ), Card.new( element: :tree, level: 2 ) ]
    expect( @generate.combination_test( cards_tested ) ).to eq( true )
    cards_tested = [ Card.new( element: :earth, level: 2 ), Card.new( element: :water, level: 1 ), Card.new( element: :fire, level: 4 ) ]
    expect( @overcome.combination_test( cards_tested ) ).to eq( true )
  end

  it "should pass the feao test for the right cards" do
    cards_tested = [
      Card.new( element: :metal, level: 3 ),
      Card.new( element: :tree, level: 3 ),
      Card.new( element: :fire, level: 3 ),
      Card.new( element: :water, level: 3 ),
      Card.new( element: :earth, level: 3 )
    ]
    expect( @feao.combination_test( cards_tested ) ).to eq( true )
  end

  context "when perform attack" do
    before ( :each ) do
      @player1.cards = [ @one_metal ].flatten
    end

    it "should attack right target with right amount of damage" do
      @player1.perform( @metal_attack, @one_metal )
      expect( @player2.team.life ).to eq( 193 )
    end

    it "should write what the performer did in current turn" do
      @player1.perform( @metal_attack, @one_metal )
      turn = @game.current_turn
      target = @metal_attack.get_target( @player1, @game )
      test_feature = {
        player: @player1,
        target: target,
        rule: @metal_attack
      }
      cards_used = @one_metal.map { |c| c.to_hash }
      event = turn.events.where( test_feature ).first
      expect( event.cards_used ).to eq( cards_used )
    end
  end

  context "when player perform copy" do
    before( :each ) do
      @player1.cards = [ @one_metal, @other_two_earthes ].flatten
      @player2.cards = [ @two_earthes ].flatten
      @imitate = Rule.find_by_name( "imitate" )
      @player1.perform( @metal_attack, @one_metal )
      @game.turn_end
      @player2.perform( @imitate, @two_earthes )
      @player1.reload
      @player2.reload
    end

    it "should copy what last player do" do
      expect( @player2.team.life ).to eq( 193 )
      expect( @player1.team.life ).to eq( 194 )
      expect( @player2.annex[:element] ).to eq( "metal" )
    end

    it "should copy the original player do when it copy imitate" do
      @game.turn_end
      @player1.perform( @imitate, @other_two_earthes )
      expect( @player2.reload.annex[:element] ).to eq( "metal" )
      expect( @player2.reload.team.life ).to eq( 188 )
      expect( @player1.reload.annex[:element] ).to eq( "metal" )
    end
  end

  context "when player perform defense" do
    before( :each ) do
      @player1.cards = [ @two_trees ].flatten
      @player2.cards = [ @another_metal, @one_tree ].flatten
      @defense = Rule.find_by_name( "defense" )
      @player1.perform( @defense, @two_trees )
      @game.turn_end
      @player2.perform( @metal_attack, @another_metal )
      @player1.reload
      @player2.reload
    end

    it "should counter opponent's attack at next turn" do
      expect( @player1.team.life ).to eq( @player1.team.life_limit )
    end

    it "should not counter opponenet's attack atfer next turn" do
      expect( @player1.annex.has_key?( :counter ) ).to be false
      @game.turn_end
      @game.turn_end
      @player2.perform( @tree_attack, @one_tree )
      @player1.reload
      @player2.reload
      expect( @player1.team.life ).to eq( 195 )
    end
  end

  context "when player perform metal_formation" do
    before( :each ) do
      @player1.cards << [ @one_metal, @two_metal, @two_other_metal, @one_earth ].flatten
      #puts "before playing metal formation"
      #pp @player1.cards
      @metal_formation = Rule.find_by_name( "metal formation" )
      @venus_attack = Rule.find_by_name( "venus attack" )
      @venus_formation = Rule.find_by_name( "venus formation" )
      @player1.perform( @metal_formation, [ @one_metal, @two_metal ].flatten )
      #puts "after playing metal formation"
      #pp @player1.cards
    end

    it "should damage opponent" do
      expect( @player2.reload.team.life ).to eq( 161 )
    end

    it "should summon venus" do
      expect( @player1.team.has_star?( "venus" ) ).to be true
    end

    it "should make venus attack avaliable" do
      expect( @venus_attack.condition_test( @game, @player1 ) ).to be true
    end

    it "should remove venus after performing venus formation" do
      @game.turn_end
      @game.turn_end
      @player1.reload
      #puts "before playing venus formation"
      #pp @player1.cards
      @player1.perform( @venus_formation, [ @two_other_metal, @one_earth ].flatten )
      expect( @player1.reload.team.has_star?( "venus" ) ).to be false
    end
  end

  context "when an effect doesn't implemented" do
    before( :each ) do
      @new_rule = Rule.new( name: "new rule", effect: JSON.parse( "{ \"hello\": \"world\" }" ) )
    end

    it "should raise an exception while performed" do
      expect{ @new_rule.performed( @player1, [], @game, 1 ) }.to raise_error( "This effect [hello] is not implemented" )
    end
  end
end
