WITH
with_bin AS (
    SELECT
    date_bin('5 minutes', time, '2025-01-01 00:00') AS bin, *
    FROM listings
    WHERE players > 0
    AND time > NOW() - INTERVAL '3 days'
),
per_server AS (
    SELECT bin, name, max(players) AS players
    FROM with_bin
    GROUP BY bin, name
),
per_small_bin AS (
    SELECT bin, sum(players) AS players
    FROM per_server
    GROUP BY bin
),
per_large_bin AS (
    SELECT
        date_bin('1 hour', bin, '2025-01-01 00:00') AS bin, players
    FROM per_small_bin
)
SELECT
bin, avg(players) AS players
FROM per_large_bin
GROUP BY bin
ORDER BY bin ASC;
