import { GameField } from "./game_field"

export class Game {
  constructor() {
    //this.info = JSON.parse(JSON.stringify(info));
    //this.view = view;
    //console.log( info );
    this.view = new GameField();
    this.update_status = this.update_status.bind(this);
    $("#player .action").on( "click", ".card", (e) => {
      this.card_selected( $(e.target), false );
    });
    $("#player .hand").on( "click", ".card", (e) => {
      this.card_selected( $(e.target), true );
    });
    $("#moves").on( "click", ".rule", (e) => {
      this.perform_rule( $(e.target) );
    });
    $("#choose").on( "click", "button", (e) => {
      this.confirm_choice();
    });
    $("#choose").on( "click", ".card", (e) => {
      console.log("in click choose");
      $(e.target).toggleClass("selected");
      this.toggle_choice( $(e.target) );
    });
    $(".secondary .discard").on( "click", ".card", (e) => {
      this.recycle( $(e.target) );
    });
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
    fetch(this.generate_url("find_opponent"))
      .then( (response) => response.json() )
      .then( this.update_status );
  }

  request_status() {
    console.log( "requesting status" );
    fetch(this.generate_url("info", $("#maincontainer").data("game_id"), $("#player").data("id")) )
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

  confirm_choice() {
    var selected_cards = this.collect_cards(this.info['choices'], "selected");
    // 選擇實體牌時，只需回傳牌的id
    let selected_ids = selected_cards.map((card, i) => {
      return card.id;
    });
    // 如果還看得到對手的牌，就先選擇對手的牌
    if (this.info['opponent']['members'][0]['annex']['showhand']) {
      this.select_opponent_hands(selected_ids);
      return;
    }
    // 如果是在產生虛擬牌，則進入選牌流程
    if (this.current_action == 'craft_card' || this.current_action == 'craft_level') {
      this.select_card_attr(selected_cards);
      return;
    }
    if (this.info.current.members[0].annex.take) {
      this.get_selected_cards(selected_ids);
      return;
    }
    this.fill_self_hands(selected_ids);
  }

  fill_self_hands(selected_ids) {
    if ( selected_ids.length > 1 ) {
      console.log( "discard too manay!" );
      return;
    }
    console.log( selected_ids );
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("discard"),
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

  get_selected_cards(selected_ids) {
    console.log("get selected cards");
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("take"),
      data: {cards: selected_ids}
    }).done((data) => {
      console.log("take cards");
      console.log(data);
      self.info.current.members[0].hands = data.hands;
      self.update_status(self.info);
      $('#choose').modal('hide');
    }).fail((data) => {
      console.log("take card fails!");
      $("#choose .modal-body").prepend($("<div>").text("無法拿牌，請重新試一次。"));
    });
  }

  select_opponent_hands(selected_ids) {
    console.log( selected_ids );
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("select"),
      data: { cards: selected_ids, opponent: this.info['opponent']['members'][0]['id'] }
    }).done( ( data ) => {
      console.log("discard !");
      console.log( data );
      self.update_status( data );
      // 目前沒傳回合階段，應該已階段判斷是否該抽牌。
      if (!data.opponent.members[0].annex.showhand) {
        $('#choose').one('hidden.bs.modal', (e) => {
          self.draw_cards();
        });
      }
      $('#choose').modal('hide');
    }).fail((data) => {
      console.log("take cars fails!");
      $("#choose .modal-body").prepend($("<div>").text("無法拿牌，請重新試一次。"));
    });
  }

  turn_end(){
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("turn_end")
    }).done( (data) => {
      console.log("turn end");
      console.log(data);
      self.update_status( data );
    });
  }

  collect_cards(action, condition = null) {
    let filtered = action;
    if (condition != null) {
      filtered = action.filter((card, index) => {
        return card[condition];
      });
    }
    return filtered;
  }

  request_possible_moves( action ) {
    console.log( "request possible moves" );
    let card_ids = this.collect_cards(action).map((card, i) => {
      return card.id;
    });
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("possible_moves"),
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
    let card_ids = this.collect_cards(action).map((card, i) => {
      return card.id;
    });
    console.log( rule.data("id") );
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("perform"),
      data: { cards: card_ids, rule: rule.data("id") }
    }).done((data) => {
      console.log("rule performed");
      console.log(data);
      self.update_status(data);
      if (data['opponent']['members'][0]['annex']['showhand']) {
        self.select_cards(data['opponent']['members'][0]['hands']);
        return;
      }
      if (data.current.members[0].annex.craft) {
        // 只能有card、element、level
        self.craft_card(data.current.members[0].annex.craft);
        return;
      }
      if (data.current.members[0].annex.take) {
        self.select_cards(data.current.members[0].annex.take.of);
        return;
      }
      self.draw_cards();
    });
  }

  draw_cards(){
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("draw"),
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

  craft_card(attr_type, attr) {
    // 因為toggle_choice是看物件的id，所以在新增虛擬卡的選項時要加上id
    if (attr_type == 'card') {
      this.info['choices'] = ['metal', 'tree', 'water', 'fire', 'earth'].map((element, index) => {
        return {'id': 'choice-' + index, 'element': element, 'level': 1};
      });
      this.current_action = 'craft_card';
    }
    if (attr_type == 'level') {
      let element = 'metal';
      if (attr['element']) {
        element = attr['element'];
      }
      this.info['choices'] = [1, 2, 3, 4, 5].map((level, index) => {
        return {'id': 'choice-' + index, 'element': element, 'level': level};
      });
      this.current_action = 'craft_level';
    }
    console.log(this.info);
    this.view.update_view(this.info);
    $('#choose').modal('show');
  }

  select_card_attr(selected_cards) {
    console.log(selected_cards);
    var crafted = {};
    if (this.current_action == 'craft_card') {
      crafted['element'] = selected_cards[0]['element'];
      this.craft_card('level', crafted);
      return;
    }
    if (this.current_action == 'craft_level') {
      // 讓遊戲物件在block裡可見
      var self = this;
      crafted = selected_cards[0];
      // 傳送回後端賦與id
      $.ajax({
        type: "GET",
        url: this.generate_url("craft"),
        data: crafted
      }).done((data) => {
        console.log("card crafted");
        console.info(data);
        self.update_status(data);
        self.current_action = null;
        $('#choose').modal('hide');
      })
      return;
    }
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
    var self = this;
    $.ajax({
      type: "GET",
      url: this.generate_url("recycle"),
      data: { cards: card.data("id") }
    }).done( (data) => {
      console.log("recycled");
      console.log(data);
      self.update_status( data );
    });
  }

  generate_url(action, game_id = this.info['id'], player_id = this.info['current']['members'][0]['id']) {
    // 基本url在/games/
    return [
      game_id,
      "players",
      player_id,
      action
    ].join("/");
  }
}
