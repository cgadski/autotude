-- Total kills
SELECT
    NULL AS plane,
    NULL AS time_bin,
    who_killed AS handle,
    count() AS stat
FROM ladder_games
NATURAL JOIN named_kills
GROUP BY handle
ORDER BY stat desc
