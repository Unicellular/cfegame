import { Game } from "games/game"

export function run(app){
  if ( $('#maincontainer').length ){
    app = new Game();
  } else if ( app && app.timerID ){
    clearInterval( app.timerID );
  }
  return app;
}
