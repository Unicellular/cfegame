class PlayersController < ApplicationController
  before_action :must_be_my_turn

  def turn_end
    @game.turn_end
    render nothing: true
  end

  def use_cards
    puts (params[:cards].map{|i, c| c['id'] })
    cards_used = @player.using( params[:cards].map{|i, c| c['id'] } )
    render json: { hands: @player.hands(true), cards_used: cards_used }
  end

  def draw
    render json: @player.draw( @game.draw_amount )
  end

  def discard
    @discard = Card.find(params[:card_id])
    discard = @player.discard( @game.draw_amount, @discard )
    render json: { hands: @player.hands(true), discard: discard }
  end

  def recycle
    @discard = Card.find(params[:card_id])
    @deck = @game.deck
    @deck.recycle( @discard )
    render nothing: true
  end

  def possible_moves
    cards = Card.find(params[:cards] || [])
    rules = Rule.all.select do |rule|
      rule.test( cards )
    end
    render json: rules.map { |rule| { id: rule.id, name: rule.chinese_name } }
  end

  def perform
    cards = Card.find(params[:cards] || [])
    rule = Rule.find(params[:rule_id])
    @player.perform( rule, cards )
    render json: @game.info(@player)
  end

  def select_card_from_target
    target = Player.find(params[:target_id])
    if target.sustained.has_key?(:remove)
      cards = Card.find(params[:cards] || [])
      target.removed( cards.first(target.sustained[:remove]) )
    end
    render json: @game.info(@player)
  end

  private

  # player must be in his turn at that game.
  def must_be_my_turn
    @game = Game.find(params[:gid])
    @player = Player.find(params[:pid])
    unless @game.turn_player == @player
      render nothing: true, status: :forbidden
    end
  end
end
