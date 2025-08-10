-- Average game duration
-- duration
SELECT
    NULL as time_bin,
    avg(duration) AS stat
FROM ladder_games
NATURAL JOIN replays
