class Choose extends React.Component {
  constructor( props ) {
    super(props);
    this.state = props;
    this.confirm_choice = this.confirm_choice.bind(this);
    this.card_clicked = this.card_clicked.bind(this);
  }

  componentWillReceiveProps( nextProps ){
    console.log( "choose change?" );
    console.log( this.state );
    console.log( nextProps );
    this.setState( nextProps );
  }

  confirm_choice( e ){
    app.confirm_choice( this );
  }

  card_clicked( clicked ){
    this.setState( ( prevState, props ) => {
      let new_choices = prevState['choices'].map(( card, index ) => {
        if ( card.id == clicked.state['info'].id ){
          card.selected = !(card.selected);
        }
        return card;
      });
      return { choices: new_choices };
    });
  }

  render() {
    let cards = this.state['choices'].map(( card, index ) =>
      <Card key={index} info={card} selected={card.selected} handle_click={this.card_clicked} />
    );
    return (
      <div id="choose" className="modal fade in" data-backdrop="static" data-keyboard="false">
        <div className="modal-lg modal-dialog">
          <div className="modal-content">
            <div className="modal-header">
              <h4>選擇一張牌</h4>
            </div>
            <div className="modal-body">
              { cards }
            </div>
            <div className="modal-footer">
              <button type="button" className="btn btn-primary" onClick={this.confirm_choice}>
                Confirm
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }
}
