-- Total time
SELECT sum(duration) || 'dc' AS stat
FROM games
NATURAL JOIN replays
