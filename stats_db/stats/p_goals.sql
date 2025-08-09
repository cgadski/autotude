-- Lifetime goals
SELECT
    name,
    count() AS stat
FROM goals
NATURAL JOIN ladder_games
NATURAL JOIN players
JOIN names ON (names.vapor = players.vapor)
GROUP BY name
ORDER BY stat DESC;
