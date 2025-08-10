-- Life expectancy
-- duration_fine
SELECT
    name,
    avg(end_tick - start_tick) AS stat
FROM ladder_games
NATURAL JOIN spawns
NATURAL JOIN players
JOIN names ON (players.vapor = names.vapor)
GROUP BY name
ORDER BY stat
