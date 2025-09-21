-- Total time
SELECT sum(duration) || 'dc' AS stat
FROM ladder_games
NATURAL JOIN replays
