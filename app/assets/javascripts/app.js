var app;
$(document).on( "turbo:load", function(){
  if ( $('#maincontainer').length ){
    app = new Game();
  } else if ( app && app.timerID ){
    clearInterval( app.timerID );
  }
});
