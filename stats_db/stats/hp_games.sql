-- Games by player and month
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        count() AS stat
    FROM players_wide
    GROUP BY handle_key, time_bin
)
SELECT * FROM tbl
UNION ALL
SELECT
    handle_key,
    NULL AS time_bin,
    sum(stat) AS stat
FROM tbl
GROUP BY handle_key
