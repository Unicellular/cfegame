var app;
$(document).on( "turbolinks:load", function(){
  if ( $('#maincontainer').length ){
    app = new Game();
  } else if ( app && app.timerID ){
    clearInterval( app.timerID );
  }
});
