-- dvd's ladder game query
-- differs from the new ladder_games by three replays
-- think my criteria is better (excludes a 3v4, includes some that were
-- real games but where server was behaving weirdly)

DROP TABLE IF EXISTS ladder_games;
CREATE TABLE ladder_games (replay_key INTEGER PRIMARY KEY REFERENCES replays (replay_key));
INSERT INTO ladder_games (replay_key)
with chronological_replays as (
	select
		*,
		started_at + duration / 30 as ended_at
	from replays
	order by started_at, ended_at, duration
),
consecutive_replays as (
	select
		*,
		lead(started_at, 1) over (partition by server) as next_started_at,
		lead(map, 1) over (partition by server) as next_map,
		lead(replay_key, 1) over (partition by server) as next_replay_key
	from chronological_replays
),
replays_that_started_ranked as (
	select DISTINCT replay_key
	from messages
	where
		player_key is null
		and chat_message = 'Starting ranked game, do not leave if playing.'
),
games_that_were_probably_not_stopped as (
	select DISTINCT replay_key
	from messages
	where
		player_key is null
		and (
			chat_message like 'Sudden Death:  First team with a point total of % wins.'
			or chat_message = 'Game over due to mercy rule.'
		)
),
games_after_restart as (
	select DISTINCT replay_key
	from messages
	where
		player_key is null
		and chat_message = 'Game has been restarted.'
)
-- a ladder game is a game that transitions from a ranked lobby and actually finishes
select consecutive_replays.next_replay_key as replay_key
from replays_that_started_ranked -- preceding game started a ranked game
inner join consecutive_replays
	on replays_that_started_ranked.replay_key = consecutive_replays.replay_key
inner join games_that_were_probably_not_stopped -- succeeeding game was not stopped
	on games_that_were_probably_not_stopped.replay_key = consecutive_replays.next_replay_key
where
	map = 'lobby_4ball' and abs(ended_at - next_started_at) < 15 -- game transitioned from ranked lobby
	and next_map != 'lobby_4ball' -- and was not played on lobby (starting ranked will never transition back into lobby)
union
-- or is a game after a restart that actually finished
select replay_key
from games_after_restart
natural join games_that_were_probably_not_stopped;
