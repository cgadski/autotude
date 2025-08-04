-- subset of ladder games
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

-- player display name := manual name (from `names` table), if it exists, or else the most frequent name by replay count
DROP VIEW IF EXISTS player_display_names;
CREATE VIEW player_display_names AS
SELECT ranked_nicks.vapor, coalesce(names.name, ranked_nicks.nick) as name
FROM names
right join (
	SELECT
		vapor,
		nick,
		nick_count,
		row_number() OVER (
			PARTITION BY vapor
			ORDER BY nick_count desc
		) AS rank
	FROM (
		SELECT vapor, nick, count(*) AS nick_count
		FROM players
		GROUP BY vapor, nick
	)
	ORDER BY vapor, rank
) AS ranked_nicks
	ON names.vapor = ranked_nicks.vapor
WHERE ranked_nicks.rank = 1;

-- outcomes of ladder games, decided by team scoring last goal
DROP VIEW IF EXISTS outcomes;
CREATE VIEW outcomes AS
SELECT
    replay_key,
    team as winner
FROM (
    SELECT
        replay_key,
        team,
        row_number() OVER (
            PARTITION BY replay_key ORDER BY tick DESC
        ) AS goal_idx
    FROM ladder_games
    NATURAL JOIN goals
)
WHERE goal_idx = 1;

-- consecutively grouped loadouts (if two consecutive spawns have the same loadout, they have the same loadout row)
drop view if exists loadouts;
create view loadouts as
with ranked_loadouts as (
	select
		spawns.*,
		row_number() over (partition by replay_key, player_key order by start_tick) as rank_in_player_and_game,
		row_number() over (partition by replay_key, player_key, plane, red_perk, green_perk, blue_perk order by start_tick) as rank_in_player_and_game_and_loadout
	from spawns
	order by replay_key, player_key
)
select
	replay_key,
	player_key,
	plane,
	red_perk,
	green_perk,
	blue_perk,
	min(start_tick) as start_tick,
	max(end_tick) as end_tick,
	sum(end_tick - start_tick) as ticks_alive
from ranked_loadouts
group by
	replay_key,
	player_key,
	plane,
	red_perk,
	green_perk,
	blue_perk,
	rank_in_player_and_game - rank_in_player_and_game_and_loadout;

-- timeline of pretty-printed player loadouts per game
drop view if exists readable_loadouts;
create view readable_loadouts as
select
	loadouts.replay_key,
	player_display_names.name as name,
	plane_names.name as plane,
	red_name.name as red_perk,
	green_name.name as green_perk,
	blue_name.name as blue_perk,
	loadouts.ticks_alive / 30 / 60 as minutes_alive,
	loadouts.ticks_alive,
	loadouts.start_tick,
	loadouts.end_tick,
	player_display_names.vapor,
	replays.stem
from loadouts
inner join players
	on loadouts.player_key = players.player_key and loadouts.replay_key = players.replay_key
inner join player_display_names
	on players.vapor = player_display_names.vapor
inner join replays
	on players.replay_key = replays.replay_key
inner join ladder_games
	on replays.replay_key = ladder_games.replay_key
left join plane_names
	on loadouts.plane = plane_names.id
left join perk_names red_name
	on loadouts.red_perk = red_name.id
left join perk_names green_name
	on loadouts.green_perk = green_name.id
left join perk_names blue_name
	on loadouts.blue_perk = blue_name.id
order by loadouts.replay_key, player_display_names.vapor, start_tick;

-- kills between "named players" (with names in the `names` table)
DROP VIEW IF EXISTS named_kills;
CREATE VIEW IF NOT EXISTS named_kills AS
SELECT
    ladder_games.replay_key AS replay_key,
    killing_player.name AS who_killed,
    dying_player.name AS who_died
FROM ladder_games
JOIN kills USING (replay_key)
LEFT JOIN players p0 ON
    p0.replay_key = kills.replay_key AND
    p0.player_key = kills.who_killed
LEFT JOIN names killing_player ON
    killing_player.vapor = p0.vapor
JOIN players p1 ON
    p1.replay_key = kills.replay_key AND
    p1.player_key = kills.who_died
JOIN names dying_player ON
    dying_player.vapor = p1.vapor
WHERE kills.who_killed IS NOT NULL;
