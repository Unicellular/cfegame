class Game {
  constructor() {
    //this.info = JSON.parse(JSON.stringify(info));
    //this.view = view;
    //console.log( info );
    this.view = new GameField();
    this.update_status = this.update_status.bind(this);
    this.request_status();
  }

  update_status( json ) {
    console.log( "status updated" );
    console.log( json );
    console.log( "timerID = " + this.timerID );
    // 如果沒有資料回傳，直接結束不做事。
    if ( !json ) {
      return;
    }
    this.info = json;
    this.view.update_view( json );
    console.log( "myturn = " + json.myturn );
    if ( json['status'] == "prepare" ){
      this.timerID = setInterval(
        () => this.find_opponent(),
        1000
      );
    } else if ( json.myturn ) {
      this.timerID = clearInterval( this.timerID );
      if ( json['current']['members'][0]['annex']['freeze'] ) {
        this.turn_end();
      } else if ( json['current']['members'][0]['hands'].length == 0 && json['current']['action'].length == 0 ){
        this.draw_cards();
      }
    } else {
      if ( typeof this.timerID == "undefined" ) {
        console.log( "setting refreshing timer" );
        this.timerID = setInterval(
          () => this.request_status(),
          1000
        );
      }
    }
  }

  find_opponent() {
    console.log( "find_opponent" );
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "find_opponent"
    ].join("/");
    fetch( url )
      .then( (response) => response.json() )
      .then( this.update_status );
  }

  request_status() {
    console.log( "requesting status" );
    let url = [
      $("#maincontainer").data( "game_id" ),
      "players",
      $("#player").data( "id" ),
      "info"
    ].join("/");
    fetch( url )
      .then( (response) => response.json() )
      .then( this.update_status );
  }

  card_selected( card, in_hand ) {
    console.log( "in card_selected" );
    console.log( card );
    let cid = card.data("id");
    let ps = this.info['current'];
    let action = ps['action'];
    let hands = ps['members'][0]['hands'];
    let from = null, to = null;
    if ( in_hand ){
      from = hands;
      to = action;
    } else {
      from = action;
      to = hands;
    }
    let target_index = from.findIndex( ( elem, index ) => {
      return elem.id == cid;
    });
    let removed_cards = from.splice( target_index, 1 );
    to.push( removed_cards[0] );
    this.request_possible_moves( action );
  }

  confirm_choice(){
    var selected_ids = this.collect_cards( this.info['choices'], "selected" );
    if ( this.info['opponent']['members'][0]['annex']['showhand'] ) {
      this.select_opponent_hands( selected_ids );
    } else {
      this.fill_self_hands( selected_ids );
    }
  }

  fill_self_hands( selected_ids ){
    if ( selected_ids.length > 1 ) {
      console.log( "discard too manay!" );
      return;
    }
    console.log( selected_ids );
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "discard"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url,
      data: { cards: selected_ids[0] }
    }).done( ( data ) => {
      console.log("discard !");
      console.log( data );
      self.info['current']['members'][0]['hands'] = data['hands'];
      self.info['discard'] = data['discard'];
      console.log( self.info );
      self.update_status( self.info );
      $('#choose').one('hidden.bs.modal', (e) => {
        self.turn_end();
      });
      $('#choose').modal('hide');
    });
  }

  select_opponent_hands( selected_ids ){
    console.log( selected_ids );
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "select"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url,
      data: { cards: selected_ids, opponent: this.info['opponent']['members'][0]['id'] }
    }).done( ( data ) => {
      console.log("discard !");
      console.log( data );
      self.update_status( data );
      $('#choose').one('hidden.bs.modal', (e) => {
        self.draw_cards();
      });
      $('#choose').modal('hide');
    });
  }

  turn_end(){
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "turn_end"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url
    }).done( (data) => {
      console.log("turn end");
      console.log(data);
      self.update_status( data );
    });
  }

  collect_cards( action, condition = null ){
    let filtered = action;
    if ( condition != null ){
      filtered = filtered.filter( ( card, index ) => {
        return card[condition];
      });
    }
    let card_ids = filtered.map( ( card, index ) => {
      return card.id;
    });
    return card_ids;
  }

  request_possible_moves( action ) {
    console.log( "request possible moves" );
    let card_ids = this.collect_cards( action );
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "possible_moves"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url,
      data: { cards: card_ids }
    }).done( ( data ) => {
      console.log("possible_moves:");
      console.log( data );
      self.info['possible_moves'] = data.map( ( rule, index ) => {
        return rule;
      });
      console.log( self.info );
      self.update_status( self.info );
    });
  }

  perform_rule( rule ){
    let action = this.info['current']['action'];
    let card_ids = this.collect_cards( action );
    console.log( rule.data("id") );
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "perform"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url,
      data: { cards: card_ids, rule: rule.data("id") }
    }).done( (data) => {
      console.log("rule performed");
      console.log(data);
      self.update_status( data );
      if ( data['opponent']['members'][0]['annex']['showhand'] ) {
        self.select_cards( data['opponent']['members'][0]['hands'] );
      } else {
        self.draw_cards();
      }
    });
  }

  draw_cards(){
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "draw"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url,
      dataType: "json"
    }).done( (data) => {
      console.log("card drawed");
      console.log(data);
      this.info['choices'] = data.map( ( card, index ) => {
        card.selected = false;
        return card;
      });
      console.log( this.info );
      this.view.update_view( this.info );
      $('#choose').modal('show');
    });
  }

  select_cards( hands ){
    this.info['choices'] = hands.map( ( card, index ) => {
      card.selected = false;
      return card;
    });
    console.log( this.info );
    this.view.update_view( this.info );
    $('#choose').modal('show');
  }

  toggle_choice( clicked ){
    this.info['choices'] = this.info['choices'].map( ( card, index ) => {
      if ( card.id == clicked.data('id') ){
        card.selected = !(card.selected);
      }
      return card;
    });
  }

  recycle( card ){
    let url = [
      this.info['id'],
      "players",
      this.info['current']['members'][0]['id'],
      "recycle"
    ].join("/");
    var self = this;
    $.ajax({
      type: "GET",
      url: url,
      data: { cards: card.data("id") }
    }).done( (data) => {
      console.log("recycled");
      console.log(data);
      self.update_status( data );
    });
  }

}
