class GameField {
  constructor(){
    $("#player .action").on( "click", ".card", (e) => {
      app.card_selected( $(e.target), false );
    });
    $("#player .hand").on( "click", ".card", (e) => {
      app.card_selected( $(e.target), true );
    });
    $("#moves").on( "click", ".rule", (e) => {
      app.perform_rule( $(e.target) );
    });
    $("#choose").on( "click", "button", (e) => {
      app.confirm_choice();
    });
    $("#choose").on( "click", ".card", (e) => {
      console.log("in click choose");
      $(e.target).toggleClass("selected");
      app.toggle_choice( $(e.target) );
    });
    $(".secondary .discard").on( "click", ".card", (e) => {
      app.recycle( $(e.target) );
    });
  }

  update_view( game_data ){
    var cards_data;
    var show;
    $(".secondary .discard").empty().append( this.generate_card( game_data.discard, true ) );
    var message = game_data.status == "over" ?
      ( game_data.winning ? "You Win!" : "You Lose" ) :
      ( game_data.myturn ? "Your Turn" : "Opponent Turn" );
    $("#message_field").text( message );
    $("#player .hand").empty().append( this.generate_card_list( game_data.current.members[0].hands, true, false ) );
    $("#player .action").empty().append( this.generate_card_list( game_data.current.action, true, true ) );
    $("#opponent .hand").empty().append( this.generate_card_list( game_data.opponent.members[0].hands, false, false ) );
    $("#player .used").empty().append( this.generate_last_act( game_data.current.members[0].last_acts[0] ) );
    $("#opponent .action").empty().append( this.generate_last_act( game_data.opponent.members[0].last_acts[0] ) );
    $("#opponent .used").empty().append( this.generate_last_act( game_data.opponent.members[0].last_acts[1] ) );
    $("#player .life").empty().append( game_data.current.life );
    $("#player .shield").empty().append( game_data.current.members[0].shield );
    $("#opponent .life").empty().append( game_data.opponent.life );
    $("#opponent .shield").empty().append( game_data.opponent.members[0].shield );
    $("#choose .modal-body").empty().append( this.generate_card_list( game_data.choices, true, false ) );
    $("#moves .row").empty().append( this.generate_rule_list( game_data.possible_moves ) );
  }

  generate_card( card_data, is_small ){
    let class_list = [ "card" ];
    let text = "";
    let card_id = card_data ? card_data.id : null;
    if ( is_small ){
      class_list.push( "card-sm" );
    } else {
      class_list.push( "card-lg" );
    }

    if ( card_data && card_data.element ){
      class_list.push( card_data.element );
      text = card_data.level;
      if ( card_data.selected ){
        class_list.push( "selected" );
      }
    }

    return $("<div>").text(text).addClass( class_list.join( " " ) ).data( "id", card_id );
  }

  generate_card_list( cards_data, show, is_small ){
    var cards = [];
    if ( show ){
      cards = cards_data.map(( card, index ) => {
          return this.generate_card( card, is_small );
        }
      );
    } else {
      for ( var i = 0; i < cards_data; i++ ){
        cards.push( this.generate_card( {}, is_small ) );
      }
    }
    return cards;
  }

  generate_last_act( last_act ){
    if ( last_act && last_act.cards_used ){
      return this.generate_card_list( last_act.cards_used, true, true );
    } else if ( last_act && last_act.cards_count ) {
      return this.generate_card_list( last_act.cards_count, false, true );
    } else {
      return [];
    }
  }

  generate_rule_list( rules_data ){
    var rules = [];
    rules = rules_data.map(( rule, index ) => {
      return $("<div>").text( rule.name ).addClass( "col-md-4 rule" ).data( "id", rule.id );
    });
    console.log( rules );
    return rules;
  }
}
