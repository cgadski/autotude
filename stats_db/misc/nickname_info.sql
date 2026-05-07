SELECT
    vapor, name, group_concat(DISTINCT nick)
FROM games
NATURAL JOIN players
JOIN handles USING (vapor)
WHERE vapor != ''
AND team > 2
GROUP BY vapor, name
ORDER BY vapor;
