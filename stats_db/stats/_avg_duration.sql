-- Average game length
SELECT avg(duration) || 'd' AS stat
FROM ladder_games
NATURAL JOIN replays
