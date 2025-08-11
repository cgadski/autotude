-- Ranked games
WITH tbl AS (
    SELECT
        time_bin,
        count() AS stat
    FROM ladder_games
    NATURAL JOIN time_bins
    GROUP BY time_bin
)
SELECT * FROM tbl
UNION ALL
SELECT
    null AS time_bin,
    sum(stat)
FROM tbl
