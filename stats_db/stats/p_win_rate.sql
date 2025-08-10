-- Win rate
-- percentage
SELECT
    names.name,
    CAST(SUM(CASE WHEN game_meta.winner = players.team THEN 1 ELSE 0 END) AS REAL) / COUNT(*) AS stat
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN names
NATURAL JOIN game_meta
WHERE players.team > 2
GROUP BY names.vapor, names.name
HAVING count() >= 50
ORDER BY stat DESC
