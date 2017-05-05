class Action extends React.Component {
  constructor( props ){
    super( props );
    this.state = props;
    console.log( "action initial" );
    console.log( this.state['action'] );
  }

  componentWillReceiveProps( nextProps ){
    console.log( "action change?" );
    console.log( this.state );
    console.log( nextProps );
    if ( this.state['action'].length != nextProps['action'].length ){
      this.setState( nextProps );
    }
  }

  componentDidUpdate( prevProps, prevState ){}

  render () {
    let last_acts = [];
    if ( this.state['current'] ){
      last_acts[0] = this.state['action'].map(( card, index ) =>
        <Card key={index} info={card} is_small={true} in_hand={false} />
      );
      last_acts[1] = this.state['last_acts'][0]['cards_used'].map(( card, index ) =>
        <Card key={index} info={card} is_small={true} />
      );
    } else {
      for (var i = 0; i < this.state['last_acts'].length; i++) {
        if ( this.state['last_acts'][i]['cards_used'] ){
          last_acts[i] = this.state['last_acts'][i]['cards_used'].map(( card, index ) =>
            <Card key={index} info={card} is_small={true} />
          );
        } else {
          last_acts[i] = [];
          for ( var j = 0; j < this.state['last_acts'][i]; j++ ){
            last_acts[i].push( <Card key={j} is_small={true} /> );
          }
        }
      }
    }
    return (
      <div className="row">
        <div className="col-md-7">
          <div className="action row">
            { last_acts[0] }
          </div>
        </div>
        <div className="col-md-5">
          <div className="used row">
            { last_acts[1] }
          </div>
        </div>
      </div>
    );
  }
}
