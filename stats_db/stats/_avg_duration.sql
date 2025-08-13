-- Average game length
-- duration
SELECT
    avg(duration) AS stat
FROM ladder_games
NATURAL JOIN replays
