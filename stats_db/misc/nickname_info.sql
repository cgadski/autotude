SELECT
    vapor, name, group_concat(DISTINCT nick)
FROM ladder_games
NATURAL JOIN players
JOIN names USING (vapor)
WHERE vapor != ''
AND team > 2
GROUP BY vapor, name
ORDER BY vapor;
