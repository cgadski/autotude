-- Win rate
-- percentage
SELECT
    handle,
    NULL AS time_bin,
    NULL AS plane,
    CAST(SUM(CASE WHEN game_meta.winner = players.team THEN 1 ELSE 0 END) AS REAL) / COUNT(*) AS stat
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN handles
NATURAL JOIN game_meta
WHERE players.team > 2
GROUP BY handle
HAVING count() >= 50
ORDER BY stat DESC
