var app;

class Game {
  constructor( info, view ) {
    this.info = JSON.parse(JSON.stringify(info));
    this.view = view;
    console.log( info );
  }

  update_status( json ) {
    console.log( "status updated" );
    console.log( json );
    this.view.setState( json );
  }

  card_selected( card, in_hand ) {
    let cid = card.state['info']['id'];
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

  collect_cards_used( action ){
    let card_ids = action.map( ( card, index ) => {
      return card.id;
    });
    console.log( "request possible moves" );
    return card_ids;
  }

  request_possible_moves( action ) {
    let card_ids = this.collect_cards_used( action );
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
      self.view.setState( self.info );
    });
  }

  perform_rule( rule ){
    let action = this.info['current']['action'];
    let card_ids = this.collect_cards_used( action );
    console.log( rule.state );
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
      data: { cards: card_ids, rule: rule.state['rule'].id }
    }).done( (data) => {
      console.log("rule performed");
      console.log(data);
      self.update_status( data );
      if ( !data['opponent']['members'][0]['sustained']['showhand'] ) {
        draw_cards();
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
      this.view.setState( Object.assign( this.info, { choices: data } ) );
    });
  }

}
