-- One row per "server became non-empty" event over the last 24 hours.
-- An event fires when a server has >= 1 player and had no players for the
-- preceding 30 minutes. Ranked servers are excluded (bots idle there).
WITH active_minutes AS (
    SELECT
        date_trunc('minute', time) AS bin,
        name,
        max(players) AS players,
        (array_agg(map ORDER BY time DESC))[1] AS map
    FROM listings
    WHERE time > NOW() - INTERVAL '24 hours 30 minutes'
      AND players >= 1
      AND name NOT ILIKE '%ranked%'
    GROUP BY 1, 2
),
with_prev AS (
    SELECT *,
        lag(bin) OVER (PARTITION BY name ORDER BY bin) AS prev_active
    FROM active_minutes
)
SELECT bin AS time, name, players, map
FROM with_prev
WHERE (prev_active IS NULL OR prev_active < bin - INTERVAL '30 minutes')
  AND bin > NOW() - INTERVAL '24 hours'
ORDER BY time;
