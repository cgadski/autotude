WITH active_minutes AS (
    SELECT
        date_trunc('minute', time) AS bin,
        name,
        max(players) AS players,
        (array_agg(map ORDER BY time DESC))[1] AS map
    FROM listings
    WHERE time > NOW() - INTERVAL '24 hour'
      AND name NOT ILIKE '%ranked%'
    GROUP BY 1, 2
),
with_prev AS (
    SELECT *,
        lag(players) OVER (PARTITION BY name ORDER BY bin) AS prev_players,
        lag(bin) OVER (PARTITION BY name ORDER BY bin) AS prev_active
    FROM active_minutes
)
SELECT bin AS time, name, players, map
FROM with_prev
-- WHERE (prev_active IS NULL OR prev_active < bin - INTERVAL '30 minutes')
WHERE (players > 0 AND (prev_players IS NULL OR prev_players < players))
  AND bin > NOW() - INTERVAL '24 hour'
ORDER BY time;
