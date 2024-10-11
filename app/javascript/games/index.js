import { Game } from "games/game"
import { hidden_alert } from "games/sessions"

export { hidden_alert }

export function run(app){
  if ( $('#maincontainer').length ){
    app = new Game();
    app.request_status();
  } else if ( app && app.timerID ){
    clearInterval( app.timerID );
  }
  return app;
}
