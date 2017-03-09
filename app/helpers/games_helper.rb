module GamesHelper
  def display_team( team, game )
    players = team.players.collect{ |p| p.user.name }
    players << link_to('Join', join_game_team_path(game, team), method: :patch) if team.position_available?
    raw players.join(',')
  end
end
