class Player extends React.Component {
  constructor( props ){
    super( props );
    this.state = props;
    this.state['info']['action'] = [];
  }

  componentWillReceiveProps( nextProps ){
    console.log( "player change?" );
    console.log( this.state );
    console.log( nextProps );
    this.setState( nextProps );
  }

  shouldComponentUpdate( nextProps ){
    return this.state.current;
  }

  componentWillUpdate( nextProps, nextState ){
    console.log( "rendering player...");
    console.log( this.state );
    console.log( nextState );
  }

  render () {
    let cards = null;
    if ( this.state['info']['members'][0]['sustained']['showhand'] || this.state['current'] ){
      // console.log( "show hand" + this.state['info']['members'][0]['hands'] );
      cards = this.state['info']['members'][0]['hands'].map(( card, index ) =>
        <Card key={index} info={card} in_hand={true} />
      );
    } else {
      // console.log( "hide hand" + this.state['info']['members'][0]['hands'] );
      cards = [];
      for ( var i = 0; i < this.state['info']['members'][0]['hands']; i++ ){
        cards.push( <Card key={i} /> );
      }
    }
    const hand = (
      <div className="hand row">
        { cards }
      </div>
    );
    let idtag = null;
    let card_area = null;
    if ( this.state['current'] ){
      idtag = "player";
      card_area = (
        <div className="main col-md-10">
          <Action current={this.state['current']}
            last_acts={this.state['info']['members'][0]['last_acts']}
            action={this.state['info']['action']} />
          { hand }
        </div>
      );
    } else {
      idtag = "opponent";
      card_area = (
        <div className="main col-md-10">
          { hand }
          <Action current={this.state['current']}
            last_acts={this.state['info']['members'][0]['last_acts']} />
        </div>
      );
    }

    return (
      <div id={idtag} className="row">
        <div className="side col-md-2">
          <div className="life row">
            {this.state['info'].life}
          </div>
          <div className="shield row">
            {this.state['info']['members'][0]['shield']}
          </div>
        </div>
        { card_area }
      </div>
    );
  }
}
