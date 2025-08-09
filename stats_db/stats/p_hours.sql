-- Hours in-game
SELECT
    name,
    sum(cast(ticks_alive AS REAL)) / (30 * 60 * 60) AS stat
FROM ladder_games
NATURAL JOIN players
JOIN names ON (names.vapor = players.vapor)
WHERE team > 2
GROUP BY name
ORDER BY stat DESC
