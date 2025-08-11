-- Gameplay time
-- duration
WITH tbl AS (
    SELECT
        time_bin,
        sum(duration) AS stat
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN time_bins
    GROUP BY time_bin
)
SELECT * FROM tbl
UNION ALL
SELECT
    null AS time_bin,
    sum(stat)
FROM tbl
