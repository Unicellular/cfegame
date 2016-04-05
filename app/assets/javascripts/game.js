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
            clearInterval(interval);
          }
      });
    } else {
      clearInterval(interval);
    }
  }, 1000);
});
