class Card extends React.Component {
  constructor( props ){
    super( props );
    this.state = props;
    this.select_card = this.select_card.bind( this );
  }

  select_card( e ){
    app.card_selected( this, this.props['in_hand'] );
  }

  componentWillReceiveProps( nextProps ){
    //console.log( "card updating..." );
    //console.log( this.props );
    //console.log( nextProps );
    if ( this.state['info']['id'] != nextProps['info']['id'] ){
      this.setState( nextProps );
    }
  }

  render () {
    let class_list = [ "card" ];
    let text = null;
    if ( this.state["is_small"] ){
      class_list.push( "card-sm" );
    } else {
      class_list.push( "card-lg" );
    }

    if ( this.state["info"] ){
      class_list.push( this.state["info"]["element"] );
      text = this.state["info"]["element"] + this.state["info"]["level"];
      if ( this.state["is_draw"] ){
        class_list.push( "draw" );
      }
    }
    return (
      <div className={ class_list.join( " " ) } onClick={this.select_card}>
        { text }
      </div>
    );
  }
}
