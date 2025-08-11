-- Life expectancy
-- duration_fine
SELECT
    handle,
    NULL AS time_bin,
    NULL AS plane,
    avg(end_tick - start_tick) AS stat
FROM ladder_games
NATURAL JOIN spawns
NATURAL JOIN players
NATURAL JOIN handles
GROUP BY handle
ORDER BY stat
