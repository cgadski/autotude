WITH
with_bin AS (
    SELECT
    date_bin('5 minutes', time, '2025-01-01 00:00') AS bin, *
    FROM listings
    WHERE players > 0
)
SELECT bin, name, max(players) FROM with_bin
GROUP BY bin, name
ORDER BY bin DESC
LIMIT 20;
