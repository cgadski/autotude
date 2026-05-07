-- Average game length
SELECT avg(duration) || 'd' AS stat
FROM games
NATURAL JOIN replays
