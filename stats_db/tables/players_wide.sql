BEGIN;

-- Each row in this table corresponds to a "loadout period"
-- during which a player had the same player key and loadout.
CREATE TABLE IF NOT EXISTS players_wide (
    -- main characteristics of loadout period
    replay_key INTEGER REFERENCES replays (replay_key),
    vapor_key INTEGER REFERENCES vapors (vapor_key),
    handle_key INTEGER REFERENCES handles (handle_key),
    plane INTEGER,
    red_perk INTEGER,
    green_perk INTEGER,
    blue_perk INTEGER,
    player_key INTEGER,

    time_bin INTEGER, -- month of game, for grouping
    team INTEGER, -- team of player, constant over loadouts
    start_tick, -- first tick of loadout
    end_tick, -- first tick NOT in loadout: time player spawns as a different plane/player_key. can be null

    -- data per loadout period
    time_alive REAL, -- time player was alive
    kills INTEGER,
    team_kills INTEGER,
    deaths INTEGER,
    goals INTEGER,
    time_with_ball INTEGER
);

CREATE INDEX IF NOT EXISTS idx_players_wide
    ON players_wide (handle_key, plane);
CREATE INDEX IF NOT EXISTS idx_players_wide_replay
    ON players_wide (replay_key, vapor_key);

CREATE TEMP TABLE replays_fresh AS
SELECT replay_key
FROM ladder_games
WHERE replay_key NOT IN (SELECT replay_key FROM players_wide);

-- Rows of spawn_groups are one-to-one with rows of players_wide:
-- they describe the loadout, player_key, and start/end tick for
-- each row.
CREATE TEMP TABLE spawn_groups AS
-- We first decorate spawns with handles, teams, and a clever window
-- function that characterizes runs of consecutive spawns sharing
-- the same attributes (loadout + player_key).
WITH spawns_wide AS (
    SELECT -- ~1,000,000 rows (3s, expensive part is sorting for window fns)
        replay_key, vapor_key,
        plane, red_perk, green_perk, blue_perk, player_key, team,
        start_tick, end_tick,
        (row_number() OVER
            (PARTITION BY replay_key, vapor_key ORDER BY start_tick))
        - (row_number() OVER
            (PARTITION BY replay_key, vapor_key, plane, red_perk, green_perk, blue_perk, player_key ORDER BY start_tick))
        AS spawn_group
    FROM spawns
    JOIN players USING (replay_key, player_key)
    NATURAL JOIN vapors
    WHERE replay_key IN (SELECT replay_key FROM replays_fresh)
)
SELECT -- ~50,000 rows
    replay_key, vapor_key,
    plane, red_perk, green_perk, blue_perk, player_key,
    team,
    sum(end_tick - start_tick) AS time_alive,
    min(start_tick) AS start_tick,
    lead(min(start_tick), 1)
        OVER (PARTITION BY replay_key, vapor_key ORDER BY start_tick)
        AS end_tick
        -- in sqlite, window functions happen after grouping
FROM spawns_wide
GROUP BY replay_key, vapor_key, spawn_group;

SELECT 'Considering ' || count() || ' new spawn groups' FROM spawn_groups;

INSERT INTO players_wide
WITH kill_tallies AS (
    SELECT
        sg.rowid,
        count() FILTER (WHERE kills.who_killed = sg.player_key) AS kills,
        count() FILTER (
            WHERE kills.who_killed = sg.player_key
            AND p_died.team = sg.team
        ) AS team_kills,
        count() FILTER (WHERE kills.who_died = sg.player_key) AS deaths
    FROM spawn_groups sg
    JOIN kills ON (
        kills.replay_key = sg.replay_key AND
        kills.tick >= sg.start_tick AND
        coalesce(kills.tick < sg.end_tick, true)
    )
    LEFT JOIN players p_died ON (
        kills.replay_key = p_died.replay_key AND
        kills.who_died = p_died.player_key
    )
    GROUP BY sg.rowid
),
goal_tallies AS (
    SELECT
        sg.rowid,
        count() AS goals
    FROM spawn_groups sg
    JOIN goals ON (
        goals.replay_key = sg.replay_key AND
        goals.player_key = sg.player_key AND
        goals.tick >= sg.start_tick AND
        coalesce(goals.tick < sg.end_tick, true)
    )
    GROUP BY sg.rowid
),
time_with_ball AS (
    SELECT
        sg.rowid,
        sum(p.end_tick - p.start_tick) AS time_with_ball
    FROM spawn_groups sg
    JOIN possession p ON (
        p.replay_key = sg.replay_key AND
        p.player_key = sg.player_key AND
        p.start_tick >= sg.start_tick AND
        coalesce(p.start_tick < sg.end_tick, true)
    )
    GROUP BY sg.rowid
)
SELECT
    -- loadout characteristics
    replay_key, vapor_key, null AS handle_key,
    plane, red_perk, green_perk, blue_perk, player_key,

    -- some helpful columns
    time_bin, team,
    start_tick, end_tick,

    -- now the interesting queries
    time_alive,
    coalesce(kills, 0) AS kills,
    coalesce(team_kills, 0) AS team_kills,
    coalesce(deaths, 0) AS deaths,
    coalesce(goals, 0) AS goals,
    coalesce(time_with_ball, 0) AS time_with_ball
FROM spawn_groups sg
JOIN replays_wide USING (replay_key)
LEFT JOIN kill_tallies ON (sg.rowid = kill_tallies.rowid)
LEFT JOIN goal_tallies ON (sg.rowid = goal_tallies.rowid)
LEFT JOIN time_with_ball ON (sg.rowid = time_with_ball.rowid)
ORDER BY start_tick;

UPDATE players_wide
SET handle_key = (
    SELECT vh.handle_key FROM vapor_handle vh
    WHERE vh.vapor_key = players_wide.vapor_key
);

DELETE FROM players_wide
WHERE replay_key NOT IN ladder_games;

COMMIT;
