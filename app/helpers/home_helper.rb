module HomeHelper
  def display_team( team, game )
    players = team.players.collect{ |p| p.user.name }
    players << link_to('Join', join_path(game, team), method: :patch) if team.position_available?
    sanitize players.join ','
  end
end
