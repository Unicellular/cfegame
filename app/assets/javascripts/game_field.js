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
    this.display_player( true, game_data.current );
    this.display_player( false, game_data.opponent );
    $("#field").text(game_data.field);
    $("#choose .modal-body").empty().append( this.generate_card_list( game_data.choices, true, false ) );
    $("#moves .row").empty().append( this.generate_rule_list( game_data.possible_moves ) );
  }

  display_player( is_current, data ){
    var html_id;
    var visible;
    var action_cards;
    var used_cards;
    var hero = data.members[0].annex.hero ? data.members[0].annex.hero : "無職業";
    // 防止對手尚未出現時，opponent物件不存在的問題。
    if ( !data.members[0] ){
      data.members[0] = { "last_acts": [], "hands": [], "shield": 0, "star_history": [] };
    }

    if ( is_current ){
      html_id = "#player";
      visible = true;
      action_cards = this.generate_card_list( data.action, true, true );
      used_cards = this.generate_last_act( data.members[0].last_acts[0] );
    } else {
      html_id = "#opponent";
      visible = false;
      action_cards = this.generate_last_act( data.members[0].last_acts[0] );
      used_cards = this.generate_last_act( data.members[0].last_acts[1] );
    }
    $(html_id + " .hand").empty().append(this.generate_card_list(data.members[0].hands, visible, false));
    $(html_id + " .life").empty().append(data.life);
    $(html_id + " .shield").empty().append(data.members[0].shield);
    $(html_id + " .action").empty().append(action_cards);
    $(html_id + " .used").empty().append(used_cards);
    $(html_id + " .star_history").empty().append(this.generate_star_history(data.members[0].star_history));
    $(html_id + " .current_star").empty().append($("<div>").text("★").addClass("star " + data.star));
    $(html_id + " .hero").text(hero)
  }

  generate_star_history( star_history ){
    let all_star = ["venus", "jupiter", "mercury", "mars", "saturn"];
    let stars = all_star.map(( star, index ) => {
      if ( star_history.indexOf( star ) != -1 ){
        return $("<div>").text("★").addClass( "star " + star );
      } else {
        return $("<div>").text("☆").addClass( "star " + star );
      }
    });
    return stars;
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
