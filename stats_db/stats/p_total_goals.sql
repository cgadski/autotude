-- Total goals
SELECT
    NULL AS plane,
    NULL AS time_bin,
    handle,
    count() AS stat
FROM ladder_games
NATURAL JOIN goals
NATURAL JOIN players
NATURAL JOIN handles
GROUP BY handle
ORDER BY stat DESC
