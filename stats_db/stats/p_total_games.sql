-- Total games
SELECT
    NULL AS plane,
    NULL AS time_bin,
    handle,
    count() AS stat
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN handles
WHERE team > 2
GROUP BY handle
