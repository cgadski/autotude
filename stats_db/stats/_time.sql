-- Total game time
SELECT sum(duration) || 'd' AS stat
FROM ladder_games
NATURAL JOIN replays
