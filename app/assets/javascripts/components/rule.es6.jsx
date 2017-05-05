class Rule extends React.Component {
  constructor( props ){
    super(props);
    this.state = props;
    this.perform = this.perform.bind(this);
  }

  perform( e ){
    console.log( this );
    app.perform_rule( this );
  }

  componentWillReceiveProps( nextProps ){
    if ( this.state['rule'].id != nextProps['rule'].id ) {
      this.setState( nextProps );
    }
  }

  render(){
    return (
      <div className="col-md-4 rule" onClick={this.perform}>
        {this.state['rule'].name}
      </div>
    );
  }
}
