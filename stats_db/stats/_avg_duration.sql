-- Average game duration
-- duration
WITH tbl AS (
    SELECT
        time_bin,
        avg(duration) AS stat
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN time_bins
    GROUP BY time_bin
)
SELECT * FROM tbl
UNION ALL
SELECT
    null AS time_bin,
    avg(duration) AS stat
FROM ladder_games
NATURAL JOIN replays
