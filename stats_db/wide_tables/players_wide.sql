-- bunch of features computed for each player row
DROP TABLE IF EXISTS players_wide;
CREATE TABLE players_wide (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    team INTEGER,
    handle_key INTEGER REFERENCES handles (handle_key),
    time_bin INTEGER,
    nick INTEGER,
    plane INTEGER,
    time_alive REAL,
    kills INTEGER,
    deaths INTEGER,
    goals INTEGER,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX idx_players_wide_handle_key ON players_wide (handle_key);

INSERT INTO players_wide
WITH plane_usage AS (
    SELECT
        replay_key,
        player_key,
        plane,
        sum(end_tick - start_tick) AS ticks_used,
        row_number() OVER (
            PARTITION BY spawns.replay_key, spawns.player_key
            ORDER BY sum(spawns.end_tick - spawns.start_tick) DESC
        ) AS usage_rank
    FROM replays
    NATURAL JOIN spawns
    GROUP BY replay_key, player_key, plane
),
used_planes AS (
    SELECT
        replay_key,
        player_key,
        plane
    FROM plane_usage
    WHERE usage_rank = 1
),
time_alive AS (
    SELECT
        spawns.replay_key,
        spawns.player_key,
        sum(spawns.end_tick - spawns.start_tick) AS time_alive
    FROM spawns
    GROUP BY spawns.replay_key, spawns.player_key
),
kill_tallies AS (
    SELECT
        replay_key,
        player_key,
        count() FILTER (WHERE who_killed = player_key) AS kills,
        count() FILTER (WHERE who_died = player_key) AS deaths
    FROM replays
    NATURAL JOIN players
    NATURAL JOIN kills
    GROUP BY replay_key, player_key
),
goal_tallies AS (
    SELECT
        replay_key,
        player_key,
        count(*) AS goals
    FROM goals
    GROUP BY replay_key, player_key
)
SELECT
    p.replay_key,
    p.player_key,
    team,
    handle_key,
    time_bin,
    nick,
    plane,
    coalesce(time_alive, 0) AS time_alive,
    coalesce(kills, 0) AS kills,
    coalesce(deaths, 0) AS deaths,
    coalesce(goals, 0) AS goals
FROM replays_wide
NATURAL JOIN players p
NATURAL JOIN vapor_handle
NATURAL LEFT JOIN used_planes
NATURAL LEFT JOIN time_alive
NATURAL LEFT JOIN kill_tallies
NATURAL LEFT JOIN goal_tallies;
