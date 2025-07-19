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
        row_number() OVER (PARTITION BY replay_key ORDER BY tick) as rn
    FROM ladder_games
    NATURAL JOIN goals
)
WHERE rn = 1;

DROP TABLE IF EXISTS named_kills;
CREATE TABLE named_kills AS
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

CREATE INDEX IF NOT EXISTS idx_who_killed ON named_kills (who_killed);
CREATE INDEX IF NOT EXISTS idx_who_died ON named_kills (who_died);
