-- Gameplay hours
SELECT
    cast(sum(duration) AS REAL) / (30 * 60 * 60) AS stat
    FROM ladder_games
NATURAL JOIN replays
