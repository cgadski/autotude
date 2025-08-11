-- Time in-game
-- duration
SELECT
    NULL AS plane,
    NULL AS time_bin,
    handle,
    sum(ticks_alive) AS stat
FROM ladder_games
NATURAL JOIN players
JOIN handles ON (handles.vapor = players.vapor)
WHERE team > 2
GROUP BY handle
ORDER BY stat DESC
