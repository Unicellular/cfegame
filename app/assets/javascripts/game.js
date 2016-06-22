var emap = [
  "metal",
  "water",
  "tree",
  "fire",
  "earth"
];

$(function(){
  var interval = setInterval(function(){
    var game = $('#maincontainer');
    var player = $('#player');
    var game_id;
    if( game.length ){
      game_id = game.data('game_id');
      player_id = player.data('player_id');
      $.ajax({
        url: '/find_opponent/' + game_id + '/' + player_id,
        dataType: "json"
      }).done( function(msg){
          if ( msg ) {
            console.log("opponent found!");
            console.log(msg)
            $('#player .side').html(msg['current']['team'].life);
            $('#opponent .side').html(msg['opponent']['team'].life);
            $.each( msg['current']['members'][0].hands, function( index, value ){
              $('#player .hand').append(create_card( value ));
            });
            for( var i = 0; i < msg['opponent']['members'][0].hands; i++ ){
              $('#opponent .hand').append(create_card());
            }
            clearInterval(interval);
          }
      });
    } else {
      clearInterval(interval);
    }
  }, 1000);
});

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
