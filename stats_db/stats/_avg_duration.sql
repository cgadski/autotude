-- Average game length
-- attributes: duration
SELECT
    avg(duration) AS stat
FROM ladder_games
NATURAL JOIN replays
