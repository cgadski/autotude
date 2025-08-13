DROP TABLE IF EXISTS players_meta;
CREATE TABLE players_meta (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    team INTEGER,
    handle_key INTEGER REFERENCES handles (handle_key),
    time_bin INTEGER,
    plane INTEGER,
    time_alive REAL,
    kills INTEGER,
    deaths INTEGER,
    goals INTEGER,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX idx_players_meta_handle_key ON players_meta (handle_key);

INSERT INTO players_meta
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
    FROM ladder_games
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
        up.plane,
        sum(CASE WHEN spawns.plane = up.plane THEN spawns.end_tick - spawns.start_tick ELSE 0 END) AS time_alive
    FROM spawns
    JOIN used_planes up USING (replay_key, player_key)
    GROUP BY spawns.replay_key, spawns.player_key, up.plane
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
    plane,
    time_alive,
    coalesce(kills, 0) AS kills,
    coalesce(deaths, 0) AS deaths,
    coalesce(goals, 0) AS goals
FROM ladder_games
NATURAL JOIN players p
NATURAL JOIN handles
NATURAL JOIN time_bins
NATURAL JOIN used_planes
NATURAL JOIN time_alive
NATURAL LEFT JOIN kill_tallies
NATURAL LEFT JOIN goal_tallies;
