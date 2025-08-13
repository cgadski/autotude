-- Total game time
-- duration
SELECT sum(duration) AS stat
FROM ladder_games
NATURAL JOIN replays
