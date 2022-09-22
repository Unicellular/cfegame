require 'rails_helper'

RSpec.describe Rule, type: :model do
  def player_perform_rule(player, rule_name, card_attrs)
    used_cards = card_attrs.map do |attr|
      Card.new(element: attr[0], level: attr[1])
    end
    rule = Rule.find_by_name(rule_name)
    player.cards = used_cards
    player.perform(rule, used_cards)
  end

  before( :each ) do
    # 測試前準備
    @game = Game.open( User.create )
    @game.join_with( User.create, @game.teams[1] )
    @game.begin( @game.players[0] )
    @player1 = @game.players[0]
    @player2 = @game.players[1]
    @game.deck.cards << @player1.cards << @player2.cards
    @player1.reload
    @player2.reload
    # 共用基礎陣法
    @metal_attack = Rule.find_by_name("metal attack")
    @generate = Rule.find_by_name("generating formation")
    @overcome = Rule.find_by_name("overcoming formation")
    @feao = Rule.find_by_name("five element as one")
    @one_metal = [@game.deck.find_card(:metal, 3).first]
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
      @player1.cards = @one_metal
      @player1.perform(@metal_attack, @one_metal)
      @player1.set_phase(:end)
      @game.turn_end
      player_perform_rule(@player2, "imitate", [[:earth, 3], [:earth, 5]])
      @player1.reload
      @player2.reload
    end

    it "should copy what last player do" do
      expect(@player2.team.life).to eq(193)
      expect(@player1.team.life).to eq(194)
      expect(@player2.annex["element"]).to eq("metal")
    end

    it "should copy the original player do when it copy imitate" do
      @player2.set_phase(:end)
      @game.turn_end
      player_perform_rule(@player1, "imitate", [[:earth, 2], [:earth, 4]])
      expect(@player2.reload.annex["element"]).to eq("metal")
      expect(@player2.reload.team.life).to eq(188)
      expect(@player1.reload.annex["element"]).to eq("metal")
    end
  end

  context "when player perform seal" do
    before(:each) do
      player_perform_rule(@player1, "seal", [[:water, 3], [:water, 4]])
      @game.turn_end
      @player1.reload
    end

    it "should keep counter effect after current turn end" do
      expect(@player1.annex["counter"]).to eq("spell")
    end

    it "should counter opponent's spell at next turn" do
      player_perform_rule(@player2, "imitate", [[:earth, 2], [:earth, 4]])
      @player2.reload
      expect(@player2.annex["counter"]).to eq(nil)
    end
  end

  context "when player perform defense" do
    before( :each ) do
      player_perform_rule(@player1, "defense", [[:tree, 1], [:tree, 2]])
      @game.turn_end
      player_perform_rule(@player2, "metal attack", [[:metal, 5]])
      @player1.reload
      @player2.reload
    end

    it "should counter opponent's attack at next turn" do
      expect(@player1.team.life).to eq(@player1.team.life_limit)
    end

    it "should not counter opponenet's attack atfer next turn" do
      expect(@player1.annex.has_key?("counter")).to be false
      @game.turn_end
      @game.turn_end
      player_perform_rule(@player2, "tree attack", [[:tree, 1]])
      @player1.reload
      @player2.reload
      expect(@player1.team.life).to eq(195)
    end
  end

  context "when player perform backfire" do
    before(:each) do
      player_perform_rule(@player1, "backfire", [[:fire, 1], [:fire, 5]])
      @game.turn_end
    end

    it "should make opponent's attack deal half damage to both side" do
      player_perform_rule(@player2, "water formation", [[:water, 1], [:water, 3], [:water, 5]])
      expect(@player1.reload.team.life).to eq(186)
      expect(@player2.reload.team.life).to eq(186)
    end
  end

  context "when player perform metal_formation" do
    before( :each ) do
      player_perform_rule(@player1, "metal formation", [[:metal, 5], [:metal, 4], [:metal, 4]])
    end

    it "should damage opponent" do
      expect(@player2.reload.team.life).to eq(161)
    end

    it "should summon venus as well" do
      expect(@player1.team.has_star?("venus")).to be true
    end

    context "after venus summon is executed" do
      it "should make venus attack avaliable" do
        @venus_attack = Rule.find_by_name("venus attack")
        expect(@venus_attack.condition_test(@game, @player1)).to be true
      end

      it "should remove venus after performing venus formation" do
        @game.turn_end
        @game.turn_end
        @player1.reload
        player_perform_rule(@player1, "venus formation", [[:metal, 1], [:metal, 1], [:earth, 2]])
        expect(@player1.reload.team.has_star?("venus")).to be false
      end
    end

    context "when void star is performed" do
      before(:each)  do
        @game.turn_end
        player_perform_rule(@player2, "void star", [[:water, 1], [:metal, 1], [:earth, 1]])
        @player1.team.reload
      end

      it "should eject all stars" do
        expect(@player1.team.star).to eq("nothing")
      end

      it "should reduece life to whose star is ejected" do
        expect(@player1.team.life).to eq(180)
      end
    end
  end

  context "when an effect doesn't implemented" do
    before( :each ) do
      @new_rule = Rule.new( name: "new rule", effect: JSON.parse( "{ \"hello\": \"world\" }" ) )
    end

    it "should raise an exception while performed" do
      expect{ @new_rule.performed(@player1, [], @game) }.to raise_error("This effect [hello] is not implemented")
    end
  end

  context "when perform azure dragon summon" do
    before(:each) do
      player_perform_rule(@player1, "azure dragon summon", [[:tree, 1], [:tree, 2], [:tree, 3], [:tree, 4], [:tree, 5]])
    end

    it "should change the field" do
      @game.reload
      expect(@game.field).to eq("tree")
    end

    it "should deal 81 damage to player2" do
      @player2.reload
      expect(@player2.team.life).to eq(119)
    end
  end

  context "when perform azure dragon summon against defense" do
    it "should change the field and deal 81 damage" do
      player_perform_rule(@player1, "defense", [[:tree, 3], [:tree, 4]])
      @game.turn_end
      player_perform_rule(@player2, "azure dragon summon", [[:tree, 1], [:tree, 2], [:tree, 3], [:tree, 4], [:tree, 5]])
      @game.reload
      @player1.reload
      expect(@game.field).to eq("tree")
      expect(@player1.team.life).to eq(119)
    end
  end

  context "when the field is tree" do
    before( :each ) do
      @game.field = :tree
      @game.save!
    end

    it "should make tree-attack deal double damage" do
      player_perform_rule(@player1, "tree attack", [[:tree, 1]])
      @player2.reload
      expect(@player2.team.life).to eq(190)
    end

    it "should make water-attack heal opponent" do
      @player2.team.life = 150
      @player2.team.save!
      player_perform_rule(@player1, "water attack", [[:water, 3]])
      @player2.reload
      expect(@player2.team.life).to eq(157)
    end

    it "should make chaos loss its effect" do
      player_perform_rule(@player1, "chaos", [[:earth, 3], [:earth, 2], [:tree, 1], [:metal, 4]])
      @player2.reload
      expect(@player2.annex["showhand"]).to be_nil
      expect(@player2.annex["remove"]).to be_nil
    end

    context "performing void field" do
      before(:each) do
        player_perform_rule(@player1, "void field", [[:water, 2], [:metal, 2], [:fire, 2]])
        @game.reload
        @player1.reload
        @player2.reload
      end

      it "should make field disappear" do
        expect(@game.field ).to eq("nothing")
      end

      it "should make both team lost 20 life" do
        expect(@player1.team.life).to eq(180)
        expect(@player2.team.life).to eq(180)
      end
    end
  end

  context "when the seeker school is used" do
    before(:each) do
      @player1.annex["hero"] = "kind"
      @rebirth = Rule.find_by_name("rebirth")
      @all_cards = [
        Card.new(element: :tree, level: 4),
        Card.new(element: :tree, level: 5),
        Card.new(element: :fire, level: 4),
        Card.new(element: :earth, level: 1),
        Card.new(element: :metal, level: 5),
        Card.new(element: :water, level: 1),
        Card.new(element: :earth, level: 2)
      ]
    end

    it "should pass combination test of rebirth with the right cards #1" do
      right_cards = @all_cards[0..3]
      expect(@rebirth.combination_test(right_cards)).to be_truthy
    end

    it "should pass combination test of rebirth with the right cards #2" do
      right_cards = @all_cards[1..4]
      expect(@rebirth.combination_test(right_cards)).to be_truthy
    end

    it "should not pass combination test of rebirth with the wrong cards #1" do
      right_cards = @all_cards[3..5].push(@all_cards[0])
      expect(@rebirth.combination_test(right_cards)).to be_falsy
    end

    it "should not pass combination test of rebirth with the wrong cards #2" do
      right_cards = @all_cards[2..5]
      expect(@rebirth.combination_test(right_cards)).to be_falsy
    end

    it "should ignoring counter effect while performing spell" do
      @player2.annex["counter"] = "spell"
      @player2.save
      generate_cards = @all_cards[1..3]
      @player1.cards = generate_cards
      @player1.team.life = 15
      @player1.team.save
      @player1.perform(@generate, generate_cards)
      @player1.reload
      expect(@player1.team.life).to eq(45)
    end

    it "should pass all the test with the Kind" do
      @player1.cards = @all_cards[0..3]
      expect(@rebirth.test_combination_with_mastery(@all_cards[0..3], @game, @player1)).to be_truthy
      expect(@rebirth.condition_test(@game, @player1)).to be_truthy
      expect(@rebirth.restrict_test(@player1, @all_cards[0..3])).to be_truthy
      expect(@rebirth.total_test(@all_cards[0..3], @game, @player1)).to be_truthy
    end

    it "should recover 100 life after the Kind performing the rebirth #1" do
      @player1.cards = @all_cards[0..3]
      @player1.team.life = 1
      @player1.save
      @player1.perform(@rebirth, @player1.cards.to_a)
      @player1.reload
      expect(@player1.team.life).to eq(101)
    end

    it "should recover 125 life after the Kind performing the rebirth #2" do
      @player1.cards = @all_cards[1..2].push(@all_cards[0]).push(@all_cards[6])
      @player1.team.life = 1
      @player1.save
      @player1.perform(@rebirth, @player1.cards.to_a)
      @player1.reload
      expect(@player1.team.life).to eq(126)
    end
  end
end
