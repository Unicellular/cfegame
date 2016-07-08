var emap = [
  "metal",
  "water",
  "tree",
  "fire",
  "earth"
];
var interval;

$(function(){
  game_initialize();
  interval = setInterval(find_opponent, 1000);
});

function find_opponent(){
  var game_id;
  if( game.length ){
    game_id = game.data('game_id');
    player_id = player.data('player_id');
    $.ajax({
      url: "/find_opponent/" + game_id + "/" + player_id,
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
  button_use = $('#common .use_cards');
  button_draw = $('#common .draw');
  button_end = $('#common .turn_end');
  discard_area = $('.discard');
}

function update_status( msg ){
  if ( msg ) {
    console.log("status updated");
    console.log(msg)
    $('#player .side').empty();
    $('#opponent .side').empty();
    $('#player .hand').empty();
    $('#opponent .hand').empty();
    $('#player .side').html(msg['current']['team'].life);
    $('#opponent .side').html(msg['opponent']['team'].life);
    $.each( msg['current']['members'][0].hands, function( index, value ){
      $('#player .hand').append(create_card( value ));
    });
    for( var i = 0; i < msg['opponent']['members'][0].hands; i++ ){
      $('#opponent .hand').append(create_card());
    }
    if ( msg['myturn'] ) {
      hand.on( 'click', '.card', select_card );
      action.on( 'click', '.card', unselect_card );
      button_use.click(use_cards);
      button_draw.click(draw_cards);
      button_end.click(turn_end);
      discard_area.on( 'click', '.card', recycle );
      clearInterval(interval);
    }
  }
}

function create_card( value, is_draw, is_small ){
  card = $('<div>').addClass('card card-lg');
  if( value ) {
    card.html(emap[value.element-1] + '<br />' + value.level);
    card.data('element', value.element);
    card.data('level', value.level);
    card.data('id', value.id);
    if( is_draw ){
      card.addClass("draw");
    }
    if( is_small ){
      card.removeClass('card-lg').addClass('card-sm');
    }
  }
  return card;
}
