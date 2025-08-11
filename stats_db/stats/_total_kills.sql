-- Total kills
WITH tbl AS (
    SELECT
        time_bin,
        count() AS stat
    FROM kills
    NATURAL JOIN ladder_games
    NATURAL JOIN time_bins
    WHERE who_killed IS NOT null
    GROUP BY time_bin
)
SELECT * FROM tbl
UNION ALL
SELECT
    null AS time_bin,
    sum(stat)
FROM tbl
