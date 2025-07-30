select
	name,
	concat(cast(round(avg(time_alive_holding_ball), 2) * 100 as INTEGER), '%') as avg_time_alive_holding_ball,
	count(distinct replay_key) as game_count
from (
	select
		player_display_names.name,
		players.replay_key,
		sum(1.0 * (possession.end_tick - possession.start_tick) / players.ticks_alive) as time_alive_holding_ball
	from possession
	inner join outcomes
		on possession.replay_key = outcomes.replay_key
	inner join players
		on possession.player_key = players.player_key and possession.replay_key = players.replay_key
	inner join player_display_names
		on players.vapor = player_display_names.vapor
	group by player_display_names.name, players.replay_key
)
group by name
order by avg(time_alive_holding_ball) desc
