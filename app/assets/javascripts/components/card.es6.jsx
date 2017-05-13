class Card extends React.Component {
  constructor( props ){
    super( props );
    this.state = props;
    this.select_card = this.select_card.bind( this );
  }

  select_card( e ){
    if ( typeof this.state['selected'] != "undefined" ) {
      this.props.handle_click( this );
    } else {
      app.card_selected( this, this.props['in_hand'] );
    }
  }

  componentWillReceiveProps( nextProps ){
    console.log( "card updating..." );
    console.log( this.props );
    console.log( nextProps );
    let first_info_null = !(this.state['info']) && nextProps['info'];
    let second_info_null = this.state['info'] && !(nextProps['info']);
    let two_info_exist = !!(this.state['info']) && !!(nextProps['info']);
    var something_changed = false;
    if ( two_info_exist ){
      something_changed = ( this.state['info']['element'] != nextProps['info']['element'] ) ||
                          ( this.state['info']['level'] != nextProps['info']['level'] ) ||
                          ( this.state['selected'] != nextProps['selected'] );
    }
    if ( first_info_null || second_info_null || ( two_info_exist && something_changed ) ) {
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
      if ( this.state["selected"] ){
        class_list.push( "selected" );
      }
    }
    return (
      <div className={ class_list.join( " " ) } onClick={this.select_card}>
        { text }
      </div>
    );
  }
}
