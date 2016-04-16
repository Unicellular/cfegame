$(function(){
  var interval = setInterval(function(){
    var field = $('#field');
    var player = $('#player');
    var game_id;
    if( field.length ){
      game_id = field.data('game_id');
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

function create_card( value ){
  card = $('<div>').addClass('card card-lg');
  if( value ) {
    card.html(value.element + ':' + value.level);
  }
  return card;
}
