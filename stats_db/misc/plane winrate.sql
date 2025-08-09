select
	plane_names.name as plane,
	concat(round(sum(iif(outcomes.winner = players.team, 1.0 * loadouts.ticks_alive / players.ticks_alive, 0.0)) / sum(1.0 * loadouts.ticks_alive / players.ticks_alive), 3) * 100, '%') as win_rate,
	round(sum(1.0 * loadouts.ticks_alive / players.ticks_alive) / cnt, 1) as avg_players_per_game,
	concat(cast(round(sum(1.0 * loadouts.ticks_alive / players.ticks_alive) / cnt, 2) * 100 * 5 / 8 as INTEGER), '%') as popularity, -- in a game of 8 players and 5 planes, we expect 8/5 of each plane per game
	cast(sum(iif(outcomes.winner = players.team, 1.0 * loadouts.ticks_alive / players.ticks_alive, 0.0)) as INTEGER) as games_won,
	cast(sum(1.0 * loadouts.ticks_alive / players.ticks_alive) as INTEGER) as games_played
from loadouts
inner join outcomes
	on loadouts.replay_key = outcomes.replay_key
inner join players
	on loadouts.replay_key = players.replay_key and loadouts.player_key = players.player_key
inner join plane_names
	on loadouts.plane = plane_names.id
left join (select count(*) as cnt from ladder_games)
	on true
group by loadouts.plane
order by sum(iif(outcomes.winner = players.team, 1.0 * loadouts.ticks_alive / players.ticks_alive, 0.0)) / sum(1.0 * loadouts.ticks_alive / players.ticks_alive) desc -- unrounded win_rate
