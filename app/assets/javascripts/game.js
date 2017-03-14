var emap = [
  "metal",
  "water",
  "tree",
  "fire",
  "earth"
];
var interval;

$(document).on('turbolinks:load', function(){
  if ( $('#maincontainer').length ) {
    game_initialize();
    interval = setInterval( request_status, 1000 );
    console.log( "set interval = " + interval );
  } else {
    console.log( "clear an interval = " + interval );
    clearInterval(interval);
  }
});

function find_opponent(){
  var game_id;
  if( game.length ){
    game_id = game.data('game_id');
    player_id = player.data('player_id');
    $.ajax({
      url: [game.data('game_id'), "players", player_id, "find_opponent"].join("/"),
      dataType: "json"
    }).done( update_status );
  } else {
    clearInterval(interval);
  }
}

function game_initialize(){
  game = $('#maincontainer');
  hand = $('#player .hand');
  action = $('#player .action');
  used = $('#player .used');
  player = $('#player');
  button_draw = $('#common .draw');
  button_end = $('#common .turn_end');
  discard_area = $('.discard');
  moves = $('.moves');
  opponent_hand = $('#opponent .hand');
  opponent = $('#opponent');
  player_used = $('#player .used');
  opponent_used = $('#opponent .used');
  opponent_action = $('#opponent .action');
}

function update_status( msg ){
  var message_field = $('#field');
  if ( msg && msg['status'] == "start" ) {
    console.log("status updated");
    console.log(msg)
    //$('#player .side').empty();
    //$('#opponent .side').empty();
    hand.empty();
    opponent_hand.empty();
    action.empty();
    player_used.empty();
    opponent_action.empty();
    opponent_used.empty();
    $('#player .life').html(msg['current']['team'].life);
    $('#opponent .life').html(msg['opponent']['team'].life);
    $('#player .shield').html(msg['current']['members'][0].shield);
    $('#opponent .shield').html(msg['opponent']['members'][0].shield);
    $.each( msg['current']['members'][0].hands, function( index, value ){
      hand.append(create_card( value ));
    });
    disable_activity();
    if ( msg['opponent']['members'][0]['sustained']['showhand'] ){
      $.each( msg['opponent']['members'][0].hands, function( index, value ){
        opponent_hand.append(create_card( value ));
      });
    } else {
      for( var i = 0; i < msg['opponent']['members'][0].hands; i++ ){
        opponent_hand.append(create_card());
      }
    }
    if ( msg['opponent']['members'][0]['last_acts'].length > 0 ) {
      if ( msg['opponent']['members'][0]['last_acts'][0]['cards_used'] ) {
        $.each( msg['opponent']['members'][0]['last_acts'][0]['cards_used'], function( index, value ){
          opponent_action.append(create_card( value, false, true ));
        });
      } else {
        for( var i = 0; i < msg['opponent']['members'][0]['last_acts'][0]['cards_count']; i++ ){
          opponent_action.append(create_card( null, false, true ));
        }
      }
    }
    if ( msg['opponent']['members'][0]['last_acts'].length > 1 ) {
      $.each( msg['opponent']['members'][0]['last_acts'][1]['cards_used'], function( index, value ){
        opponent_used.append(create_card( value, false, true ));
      });
    }
    if ( msg['current']['members'][0]['last_acts'].length > 0 ) {
      $.each( msg['current']['members'][0]['last_acts'][0]['cards_used'], function( index, value ){
        player_used.append(create_card( value, false, true ));
      });
    }
    if ( msg['myturn'] ) {
      hand.on( 'click', '.card', select_card );
      action.on( 'click', '.card', unselect_card );
      if ( msg['opponent']['members'][0]['sustained']['showhand'] ) {
        button_draw.text("Confirm");
        button_draw.click(select_card_from_opponent);
        $('#opponent .hand').on( 'click', '.card', function(){
          $(this).toggleClass('selected');
        });
      } else {
        button_draw.text("Draw");
        button_draw.click(draw_cards);
      }
      button_end.click(turn_end);
      discard_area.on( 'click', '.card', recycle );
      moves.on( 'click', '.rule', perform );
      message_field.text("Your Turn");
      clearInterval(interval);
    } else {
      message_field.text("Opponent's Turn");
    }
  } else {
    clearInterval(interval);
    interval = setInterval( find_opponent, 1000 );
  }
}

function create_card( value, is_draw, is_small ){
  card = $('<div>').addClass('card card-lg');
  if( value ) {
    card.html(value.element + '<br />' + value.level);
    card.data('element', value.element);
    card.data('level', value.level);
    card.data('id', value.id);
    if( is_draw ){
      card.addClass("draw");
    }
  }
  if( is_small ){
    card.removeClass('card-lg').addClass('card-sm');
  }
  return card;
}
