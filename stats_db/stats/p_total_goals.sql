-- Total goals
SELECT
    handle,
    NULL AS time_bin,
    NULL AS plane,
    count() AS stat
FROM ladder_games
NATURAL JOIN goals
NATURAL JOIN players
NATURAL JOIN handles
GROUP BY handle
ORDER BY stat DESC
