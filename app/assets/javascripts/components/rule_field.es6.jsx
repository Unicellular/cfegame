class RuleField extends React.Component {
  constructor( props ){
    super(props);
    this.state = props;
  }

  componentWillReceiveProps( nextProps ){
    this.setState( nextProps );
  }

  render(){
    const possible_moves = this.state['possible_moves'].map(( rule, index ) =>
      <Rule key={index} rule={rule}/>
    );
    return (
      <div className="moves col-md-4">
        {possible_moves}
      </div>
    );
  }
}
