-- Total kills
SELECT
    who_killed AS name, count() AS stat
FROM ladder_games
NATURAL JOIN named_kills
GROUP BY name
ORDER BY stat desc
