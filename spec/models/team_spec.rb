require 'rails_helper'

RSpec.describe Team, type: :model do
  before( :each ) do
    @team = Team.create()
  end

  it "should add the amount of healing point" do
    @team.life = 180
    @team.healed( 15 )
    @team.reload
    expect( @team.life ).to eq( 195 )
  end

  it "should sub the amount of attacking point" do
    @team.reduced( 15 )
    @team.reload
    expect( @team.life ).to eq( 185 )
  end

  it "should not have more life than the life_limit" do
    @team.life = 180
    @team.healed( 25 )
    @team.reload
    expect( @team.life ).to eq( @team.life_limit )
  end

  it "should not have less life than 0" do
    @team.life = 20
    @team.reduced( 25 )
    @team.reload
    expect( @team.life ).to eq( 0 )
  end
end
