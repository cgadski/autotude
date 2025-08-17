-- Each row in this table corresponds to a "loadout period"
-- during which a player had the same player key and loadout.
DROP TABLE IF EXISTS players_wide;
CREATE TABLE players_wide (
    -- main characteristics of loadout period
    replay_key INTEGER REFERENCES replays (replay_key),
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
    deaths INTEGER,
    goals INTEGER
);

CREATE INDEX idx_players_wide_handle ON players_wide (handle_key, plane);
CREATE INDEX idx_players_wide_replay ON players_wide (replay_key, handle_key);

-- Rows of spawn_groups are one-to-one with rows of players_wide:
-- they describe the loadout, player_key, and start/end tick for
-- each row.
CREATE TEMP TABLE spawn_groups AS
-- We first decorate spawns with handles, teams, and a clever window
-- function that characterizes runs of consecutive spawns sharing
-- the same attributes (loadout + player_key).
WITH spawns_wide AS (
    SELECT
        replay_key, handle_key, plane, red_perk, green_perk, blue_perk, player_key,
        team,
        start_tick, end_tick,
        (row_number() OVER
            (PARTITION BY replay_key, handle_key ORDER BY start_tick))
        - (row_number() OVER
            (PARTITION BY replay_key, handle_key, plane, red_perk, green_perk, blue_perk, player_key ORDER BY start_tick))
        AS spawn_group
    FROM ladder_games
    JOIN spawns USING (replay_key)
    JOIN player_key_handle USING (replay_key, player_key)
    JOIN players USING (replay_key, player_key)
)
SELECT
    replay_key, handle_key,
    plane, red_perk, green_perk, blue_perk, player_key,
    team,
    sum(end_tick - start_tick) AS time_alive,
    min(start_tick) AS start_tick,
    lead(start_tick, 1) OVER (PARTITION BY replay_key, handle_key ORDER BY start_tick) AS end_tick
FROM spawns_wide
GROUP BY replay_key, handle_key, spawn_group;

INSERT INTO players_wide
WITH kill_tallies AS (
    SELECT
        sg.rowid,
        count() FILTER (WHERE kills.who_died = sg.player_key) AS deaths,
        count() FILTER (WHERE kills.who_killed = sg.player_key) AS kills
    FROM spawn_groups sg
    JOIN kills ON (
        kills.replay_key = sg.replay_key AND
        kills.tick >= sg.start_tick AND
        coalesce(kills.tick < sg.end_tick, true)
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
)
SELECT
    -- loadout characteristics
    replay_key, handle_key,
    plane, red_perk, green_perk, blue_perk, player_key,

    -- some helpful columns
    time_bin, team,
    start_tick, end_tick,

    -- now the interesting queries
    time_alive,
    coalesce(kills, 0) AS kills,
    coalesce(deaths, 0) AS deaths,
    coalesce(goals, 0) AS goals
FROM spawn_groups sg
JOIN replays_wide USING (replay_key)
LEFT JOIN kill_tallies ON (sg.rowid = kill_tallies.rowid)
LEFT JOIN goal_tallies ON (sg.rowid = goal_tallies.rowid)
ORDER BY start_tick;

SELECT replay_key, handle, player_key, plane, red_perk, green_perk, blue_perk, start_tick, end_tick, time_alive, kills, deaths, goals
FROM players_wide
NATURAL JOIN handles
WHERE replay_key = 8848
ORDER BY start_tick;
