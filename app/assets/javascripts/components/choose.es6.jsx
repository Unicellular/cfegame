class Choose extends React.Component {
  constructor( props ) {
    super(props);
    this.state = props;
  }

  componentWillReceiveProps( nextProps ){
    this.setState( nextProps );
  }

  render() {
    let cards = this.state['choices'].map(( card, index ) =>{
      <Card key={index} info={card} />
    });
    return (
      <div id="choose" className="modal fade">
        <div className="modal-dialog">
          <div className="modal-content">
            <div className="modal-header">
              <h4>選擇一張牌</h4>
            </div>
            <div className="modal-body">
              { cards }
            </div>
          </div>
        </div>
      </div>
    );
  }
}
