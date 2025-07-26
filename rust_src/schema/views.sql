-- subset of ladder games
DROP VIEW IF EXISTS ladder_games;
CREATE VIEW ladder_games AS
WITH active_players AS (
    SELECT replay_key, COUNT(DISTINCT vapor) AS ct
    FROM replays
    NATURAL JOIN players
    WHERE team >= 3
    GROUP BY stem
)
SELECT replay_key FROM replays
NATURAL JOIN active_players
WHERE duration > 30 * 120 -- at least two minutes
AND active_players.ct == 8 -- exactly 8 vapor ids in game
AND map != "lobby_4ball";

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
-- DROP TABLE IF EXISTS named_kills;
CREATE TABLE IF NOT EXISTS named_kills AS
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

CREATE INDEX IF NOT EXISTS idx_kill_killed ON named_kills (who_killed);
CREATE INDEX IF NOT EXISTS idx_kill_died ON named_kills (who_died);
