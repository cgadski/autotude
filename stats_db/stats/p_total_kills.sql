-- Total kills
SELECT
    who_killed AS handle,
    NULL AS time_bin,
    NULL AS plane,
    count() AS stat
FROM ladder_games
NATURAL JOIN named_kills
GROUP BY handle
ORDER BY stat desc
