var hand;
var action;
var used;
var game;
var player;
var button_confirm;
//var button_end;
var discard_area;
var moves;
var opponent_hand;
var opponent;
var player_used;
var opponent_used;
var opponent_action;

function select_card(e){
  var self = $(this);
  self.removeClass('card-lg').addClass('card-sm');
  action.append(self);
  possible_moves(e);
}
function unselect_card(e){
  var self = $(this);
  self.removeClass('card-sm').addClass('card-lg');
  hand.append(self);
  possible_moves(e);
}
function discard(e){
  console.log("in the discard");
  var self = $(this);
  //var player = $('#player');
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "discard"].join("/"),
    data: { cards: self.data('id') },
    dataType: "json"
  }).done(function(msg){
    console.log("Card discarded!");
    console.log(msg);
    hand.find('.card').remove();
    $.each( msg['hands'], function(i, c){
      hand.append(create_card(c));
    });
    $('.secondary .discard .card').remove();
    $('.secondary .discard').append(create_card(msg['discard'],false,true));
    hand.off( 'click', '.draw.card', discard );
    hand.on( 'click', '.card', select_card );
    turn_end();
  });
}
function use_cards(e){
  var card_ids = [];
  action.find('.card').each(function(){
    var self = $(this);
    card_ids.push({
      id: self.data('id')
    });
  });
  console.log(card_ids);
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "use_cards"].join("/"),
    data: { cards: card_ids },
    dataType: "json"
  }).done(function(msg){
    console.log("card used!");
    console.log(msg);
    hand.find('.card').remove();
    $.each( msg['hands'], function(i, c){
      hand.append(create_card(c));
    });
    action.find('.card').remove();
    used.find('.card').remove();
    $.each( msg['cards_used'], function(i, c){
      used.append(create_card(c, false, true));
    });
  });
}

function draw_cards(e){
  hand.off( 'click', '.card', select_card );
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "draw"].join("/"),
    dataType: "json"
  }).done(function(msg){
    console.log("card drawed");
    console.log(msg);
    $.each(msg, function(i, c){
      hand.append(create_card(c, true));
    });
    hand.on( 'click', '.draw.card', discard );
  });
}
function turn_end(e){
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "turn_end"].join("/"),
    dataType: "json"
  }).done(function(msg){
    console.log("turn ended");
    console.log(msg);
    action.find('.card').each(function(idx, elem){
      $(elem).click();
    });
    disable_activity();
    interval = setInterval(request_status, 1000);
  });
}
function request_status(){
  console.log( "requesting status" );
  if( game.length ){
    $.ajax({
      type: "GET",
      url: [game.data('game_id'), "players", player.data('player_id'), "info"].join("/"),
      dataType: "json"
    }).done( update_status );
  } else {
    console.log( "clear interval = " + interval );
    clearInterval(interval);
  }
}
function recycle(e){
  self = $(this);
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "recycle"].join("/"),
    data: { cards: self.data("id") },
    dataType: "json"
  }).done(function(msg){
    console.log("recycled");
    console.log(msg);
    discard_area.find('.card').remove();
  });
}

function possible_moves(e){
  var card_ids = [];
  action.find('.card').each(function(){
    var self = $(this);
    card_ids.push( self.data('id') );
  });
  console.log(card_ids);
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "possible_moves"].join("/"),
    data: { cards: card_ids }
  }).done(function(msg){
    console.log("possible_moves:");
    console.log(msg);
    rules_area = $('#common .moves .row');
    rules_area.empty();
    $.each( msg, function(i, c){
      rules_area.append($("<div/>").addClass("col-md-4 rule").data("id", c.id).text(c.name));
    });
  });
}

function perform(e){
  var card_ids = [];
  action.find('.card').each(function(){
    var self = $(this);
    card_ids.push( self.data('id') );
  });
  self = $(this);
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "perform"].join("/"),
    data: { cards: card_ids, rule: self.data("id") },
    dataType: "json"
  }).done(function(msg){
    console.log("rule performed");
    console.log(msg);
    update_status(msg);
    if ( !msg['opponent']['members'][0]['sustained']['showhand'] ) {
      draw_cards();
    }
  });
}

function select_card_from_opponent(e){
  var card_ids = opponent_hand.find('.card.selected').map(function(i, e){
    return $(this).data('id');
  }).get();
  console.log("selected cards:");
  console.log(card_ids);
  $.ajax({
    type: "GET",
    url: [game.data('game_id'), "players", player.data('player_id'), "select"].join("/"),
    data: { cards: card_ids, opponent: opponent.data('opponent_id') },
    dataType: "json"
  }).done(function(msg){
    console.log("cards selected");
    console.log(msg);
    update_status(msg);
    draw_cards();
  });
}

function disable_activity(){
  hand.off( 'click' );
  action.off( 'click' );
  button_confirm.off( 'click' );
  //button_end.off( 'click' );
  discard_area.off( 'click' );
  moves.off( 'click' )
}
