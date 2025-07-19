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
    FIRST_VALUE(team) OVER (
        PARTITION BY replay_key ORDER BY tick DESC
    ) as winner
FROM ladder_games
NATURAL JOIN goals
GROUP BY replay_key;
