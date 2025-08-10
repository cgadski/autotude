-- Time in-game
-- duration
SELECT
    name,
    sum(ticks_alive) AS stat
FROM ladder_games
NATURAL JOIN players
JOIN handles ON (handles.vapor = players.vapor)
WHERE team > 2
GROUP BY name
ORDER BY stat DESC
