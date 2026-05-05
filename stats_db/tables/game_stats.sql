BEGIN;

CREATE TABLE IF NOT EXISTS game_stats (
    replay_key INTEGER REFERENCES replays (replay_key),
    handle_key INTEGER REFERENCES handles (handle_key),
    team       INTEGER,
    goals      INTEGER,
    points     INTEGER,
    kills      INTEGER,
    deaths     INTEGER,
    red_perk   INTEGER,
    green_perk INTEGER,
    blue_perk  INTEGER,
    pos        REAL,
    PRIMARY KEY (replay_key, handle_key)
);

CREATE TEMP TABLE replays_fresh AS
SELECT replay_key FROM ladder_games
WHERE replay_key NOT IN (SELECT replay_key FROM game_stats);

SELECT 'Computing game_stats for ' || count() || ' replays' FROM replays_fresh;

INSERT INTO game_stats
WITH

goal_stats AS (
    SELECT
        gw.replay_key,
        pkh.handle_key,
        count(*)       AS goals,
        sum(gw.points) AS points
    FROM goals_wide gw
    JOIN player_key_handle pkh USING (replay_key, player_key)
    WHERE gw.replay_key IN (SELECT replay_key FROM replays_fresh)
    GROUP BY gw.replay_key, pkh.handle_key
),

kill_stats AS (
    SELECT
        k.replay_key,
        pkh.handle_key,
        count(*) AS kills
    FROM kills k
    JOIN player_key_handle pkh
        ON k.replay_key = pkh.replay_key AND k.who_killed = pkh.player_key
    WHERE k.replay_key IN (SELECT replay_key FROM replays_fresh)
    GROUP BY k.replay_key, pkh.handle_key
),

death_stats AS (
    SELECT
        k.replay_key,
        pkh.handle_key,
        count(*) AS deaths
    FROM kills k
    JOIN player_key_handle pkh
        ON k.replay_key = pkh.replay_key AND k.who_died = pkh.player_key
    WHERE k.replay_key IN (SELECT replay_key FROM replays_fresh)
    GROUP BY k.replay_key, pkh.handle_key
),

pos_ticks AS (
    SELECT
        p.replay_key,
        pkh.handle_key,
        sum(p.end_tick - p.start_tick) AS ticks
    FROM possession p
    JOIN player_key_handle pkh USING (replay_key, player_key)
    WHERE p.replay_key IN (SELECT replay_key FROM replays_fresh)
    GROUP BY p.replay_key, pkh.handle_key
),

total_pos AS (
    SELECT replay_key, sum(end_tick - start_tick) AS total_ticks
    FROM possession
    WHERE replay_key IN (SELECT replay_key FROM replays_fresh)
    GROUP BY replay_key
),

best_loadout AS (
    SELECT
        replay_key,
        handle_key,
        red_perk,
        green_perk,
        blue_perk,
        row_number() OVER (
            PARTITION BY replay_key, handle_key
            ORDER BY sum(time_alive) DESC
        ) AS rn
    FROM players_wide
    WHERE replay_key IN (SELECT replay_key FROM replays_fresh)
    GROUP BY replay_key, handle_key, red_perk, green_perk, blue_perk
)

SELECT
    ps.replay_key,
    ps.handle_key,
    ps.team,
    coalesce(gs.goals,  0) AS goals,
    coalesce(gs.points, 0) AS points,
    coalesce(ks.kills,  0) AS kills,
    coalesce(ds.deaths, 0) AS deaths,
    bl.red_perk,
    bl.green_perk,
    bl.blue_perk,
    CASE
        WHEN tp.total_ticks > 0
        THEN round(100.0 * pt.ticks / tp.total_ticks)
        ELSE 0.0
    END AS pos
FROM players_short ps
LEFT JOIN goal_stats  gs USING (replay_key, handle_key)
LEFT JOIN kill_stats  ks USING (replay_key, handle_key)
LEFT JOIN death_stats ds USING (replay_key, handle_key)
LEFT JOIN pos_ticks   pt USING (replay_key, handle_key)
LEFT JOIN total_pos   tp USING (replay_key)
LEFT JOIN best_loadout bl
    ON bl.replay_key  = ps.replay_key
    AND bl.handle_key = ps.handle_key
    AND bl.rn = 1
WHERE ps.replay_key IN (SELECT replay_key FROM replays_fresh);

COMMIT;
