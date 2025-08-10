-- Total games
SELECT
    name, count() AS stat
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN names
WHERE team > 2
GROUP BY name
