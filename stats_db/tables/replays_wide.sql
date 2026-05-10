BEGIN;

-- days/months of games
CREATE TEMP VIEW replay_time_bins AS
SELECT
    replay_key,
    strftime('%Y-%m', started_at, 'unixepoch', '-12 hours', 'utc')
    AS time_bin,
    date(started_at, 'unixepoch', '-12 hours', 'utc')
    AS day_bin
FROM replays;

-- we encode time_bin (monthly periods) as an integer because we run so many
-- queries over this variable
DROP TABLE IF EXISTS time_bins;
CREATE TABLE time_bins (
    time_bin_key INTEGER PRIMARY KEY,
    time_bin TEXT UNIQUE
);

INSERT INTO time_bins (time_bin)
SELECT DISTINCT time_bin
FROM replay_time_bins ORDER BY day_bin;

-- temporary table for efficiently looking up next/prev replays
CREATE TEMP TABLE consecutive (
    replay_key INTEGER PRIMARY KEY,
    next INTEGER
);

CREATE INDEX consecutive_idx ON consecutive (next);

INSERT INTO consecutive
SELECT
    replay_key,
    lead(replay_key, 1)
    OVER (PARTITION BY server ORDER BY started_at) AS next
FROM replays;

--
-- replays_wide should be one-to-one with the replays table, adding a bunch of
-- helpful additional information for each game. For instance, we need replays_wide
-- to decide what games are ladder games, in games.sql.
CREATE TABLE IF NOT EXISTS replays_wide (
    replay_key INTEGER PRIMARY KEY REFERENCES replays (replay_key),
    time_bin, -- time bin this replay belongs to
    time_bin_key,
    day_bin TEXT, -- day bin where each "day" starts at noon UTC
    n_left, -- number of players on each team
    n_right,
    n_spec,
    n_goals,
    start_messages, -- server message counts
    stop_messages,
    restart_messages,
    player_messages,
    next_key, -- next replay on same server
    prev_key, -- previous replay on same server
    winner, -- last team that scored
    points_left,
    points_right,
    teams
);

CREATE TEMP TABLE replays_fresh AS
SELECT r.*
FROM replays r
LEFT JOIN replays_wide rw USING (replay_key)
WHERE (
    (rw.replay_key is null OR rw.next_key is null)
    AND server != ''
);

SELECT 'Updating replays_wide with ' || count() || ' new replays' FROM replays_fresh;

INSERT OR REPLACE INTO replays_wide
WITH RECURSIVE
stop_messages AS (
    SELECT
        replay_key,
        count() AS stop_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NULL
    AND (chat_message = 'Players agreed to stop game.'
    OR chat_message LIKE 'Game stopped by %')
    GROUP BY replay_key
),
start_messages AS (
    SELECT
        replay_key,
        count() AS start_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NULL
    AND chat_message LIKE 'Start Ranked vote passed with %'
    GROUP BY replay_key
),
restart_messages AS (
    SELECT
        replay_key,
        count() AS restart_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NULL
    AND chat_message = 'Game has been restarted.'
    GROUP BY replay_key
),
player_messages AS (
    SELECT
        replay_key,
        count() AS player_messages
    FROM replays_fresh NATURAL JOIN messages
    WHERE player_key IS NOT NULL
    GROUP BY replay_key
),
n_players AS (
    SELECT
        replay_key,
        count(DISTINCT VAPOR) FILTER (WHERE team = 3) AS n_left,
        count(DISTINCT VAPOR) FILTER (WHERE team = 4) AS n_right,
        count(DISTINCT VAPOR) FILTER (WHERE team = 2) AS n_spec
    FROM replays_fresh
    NATURAL JOIN players
    GROUP BY replay_key
),
n_goals AS (
    SELECT
        replay_key,
        count() FILTER (WHERE player_key IS NOT NULL) AS n_goals
    FROM replays_fresh
    LEFT JOIN goals USING (replay_key)
    GROUP BY replay_key
),
points AS (
    SELECT
        replay_key,
        sum(points) FILTER (WHERE team = 3) AS points_left,
        sum(points) FILTER (WHERE team = 4) AS points_right
    FROM replays_fresh
    LEFT JOIN goals_wide USING (replay_key)
    GROUP BY replay_key
),
winner AS (
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
        FROM replays_fresh
        NATURAL JOIN goals
    )
    WHERE goal_idx = 1
),
team_players AS (
    SELECT
        replay_key,
        team,
        json_group_array(
            handle
        ) AS players_json
    FROM (
        SELECT DISTINCT
            replay_key,
            handle,
            max(team) AS team
        FROM players
        NATURAL JOIN player_key_handle
        NATURAL JOIN handles
        WHERE team >= 3
        GROUP BY replay_key, handle
    )
    GROUP BY replay_key, team
),
teams AS (
    SELECT
        replay_key,
        json_group_object(team, json(players_json)) AS teams
    FROM team_players
    GROUP BY replay_key
)
SELECT
    r.replay_key,
    time_bin, -- time_bin_keys
    time_bin_key,
    day_bin,
    coalesce(n_left, 0),
    coalesce(n_right, 0),
    coalesce(n_spec, 0),
    coalesce(n_goals, 0),
    coalesce(start_messages, 0) AS start_messages,
    coalesce(stop_messages, 0) AS stop_messages,
    coalesce(restart_messages, 0) AS restart_messages,
    coalesce(player_messages, 0) AS player_messages,
    a.next AS next_key,
    b.replay_key AS prev_key,
    winner,
    coalesce(points_left, 0) AS points_left,
    coalesce(points_right, 0) AS points_right,
    teams
FROM replays_fresh r
JOIN replay_time_bins USING (replay_key)
JOIN time_bins USING (time_bin)
NATURAL LEFT JOIN n_players
NATURAL LEFT JOIN n_goals
NATURAL LEFT JOIN points
NATURAL LEFT JOIN start_messages
NATURAL LEFT JOIN stop_messages
NATURAL LEFT JOIN restart_messages
NATURAL LEFT JOIN player_messages
NATURAL LEFT JOIN teams
LEFT JOIN consecutive a ON (r.replay_key = a.replay_key)
LEFT JOIN consecutive b ON (r.replay_key = b.next)
NATURAL LEFT JOIN winner;

COMMIT;
