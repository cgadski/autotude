WITH active_minutes AS (
    SELECT
        date_trunc('minute', time) AS bin,
        name,
        max(players) AS players,
        (array_agg(map ORDER BY time DESC))[1] AS map
    FROM listings
    WHERE time > NOW() - INTERVAL '24 hour 5 minute'
      AND name NOT ILIKE '%ranked%'
    GROUP BY 1, 2
),
with_prev AS (
    SELECT *,
        max(players) OVER (
            PARTITION BY name ORDER BY bin
            RANGE BETWEEN INTERVAL '5 minute' PRECEDING
                      AND INTERVAL '1 minute' PRECEDING
        ) AS prev_players
    FROM active_minutes
)
SELECT bin AS time, name, players, map
FROM with_prev
-- more players than there were at any point over the last 5 minutes?
WHERE (players > 0 AND (prev_players IS NULL OR prev_players < players))
  AND bin > NOW() - INTERVAL '24 hour'
ORDER BY time;
