-- Total goals
SELECT
    name, count() AS stat
FROM ladder_games
NATURAL JOIN goals
NATURAL JOIN players
NATURAL JOIN handles
GROUP BY name
ORDER BY stat DESC
