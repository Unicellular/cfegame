class GameField extends React.Component {
  constructor( props ){
    super(props);
    this.state = props;
    console.log( "in game field constructor" );
    console.log( this.state['possible_moves'] );
  }

  componentDidMount(){
    app = new Game( this.props, this );
  }

  componentWillUnmount() {
    clearInterval( app.timerID );
  }

  render() {
    return (
      <div id="maincontainer" className="row">
        <div className="primary">
          <Player info={this.state.opponent} current={false} />
          <div id="common" className="row">
            <div id="field" className="col-md-2">
            </div>
            <div className="col-md-1">
              <span className="glyphicon glyphicon-chevron-left" aria-hidden="true"></span>
            </div>
            <RuleField possible_moves={this.state['possible_moves']} />
            <div className="col-md-1">
              <span className="glyphicon glyphicon-chevron-right" aria-hidden="true"></span>
            </div>
            <div className="col-md-2">
              <button className="confirm.btn.btn-default" disabled="disabled">
                Confirm
              </button>
            </div>
            <div id="message_field" className="col-md-2">
              { this.state.status == "over" ?
                ( this.state.winning ? "You Win!" : "You Lose" ) :
                ( this.state.myturn ? "Your Turn" : "Opponent Turn" ) }
            </div>
          </div>
          <Player info={this.state.current} current={true} />
        </div>
        <div className="secondary">
          <div className="discard row">
            <Card is_small={true} info={this.state.discard} />
          </div>
        </div>
        <Choose choices={this.state['choices']} />
      </div>
    );
  }
}
