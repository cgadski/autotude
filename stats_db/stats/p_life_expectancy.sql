-- Life expectancy
-- duration_fine
SELECT
    NULL AS plane,
    NULL AS time_bin,
    handle,
    avg(end_tick - start_tick) AS stat
FROM ladder_games
NATURAL JOIN spawns
NATURAL JOIN players
NATURAL JOIN handles
GROUP BY handle
ORDER BY stat
