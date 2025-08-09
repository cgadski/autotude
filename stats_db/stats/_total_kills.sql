-- Total kills
SELECT count() AS stat
FROM kills
NATURAL JOIN ladder_games
WHERE who_killed IS NOT null
