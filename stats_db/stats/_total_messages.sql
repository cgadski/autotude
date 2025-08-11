-- Total messages
WITH tbl AS (
    SELECT
        time_bin,
        count() AS stat
    FROM messages
    NATURAL JOIN time_bins
    WHERE player_key IS NOT NULL
    GROUP BY time_bin
)
SELECT * FROM tbl
UNION ALL
SELECT
    null AS time_bin,
    sum(stat)
FROM tbl
