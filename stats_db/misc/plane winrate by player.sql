select
	player_display_names.name as player,
	plane_names.name as plane,
	concat(round(sum(iif(outcomes.winner = players.team, 1.0 * loadouts.ticks_alive / players.ticks_alive, 0.0)) / sum(1.0 * loadouts.ticks_alive / players.ticks_alive), 3) * 100, '%') as win_rate,
	cast(sum(iif(outcomes.winner = players.team, 1.0 * loadouts.ticks_alive / players.ticks_alive, 0.0)) AS INTEGER) as games_won,
	cast(sum(1.0 * loadouts.ticks_alive / players.ticks_alive) as INTGER) as games_played,
	players.vapor
from loadouts
inner join outcomes
	on loadouts.replay_key = outcomes.replay_key
inner join players
	on loadouts.replay_key = players.replay_key and loadouts.player_key = players.player_key
inner join player_display_names
	on players.vapor = player_display_names.vapor
inner join plane_names
	on loadouts.plane = plane_names.id
left join (select count(*) as cnt from ladder_games)
	on true
group by player_display_names.name, loadouts.plane
having games_played > 50
order by sum(iif(outcomes.winner = players.team, 1.0 * loadouts.ticks_alive / players.ticks_alive, 0.0)) / sum(1.0 * loadouts.ticks_alive / players.ticks_alive) desc -- unrounded win_rate
