WITH recent_listings AS (
    SELECT DISTINCT ON (name) name, map, time, players
    FROM listings
    WHERE time >= NOW() - INTERVAL '2 minutes'
    ORDER BY name, time DESC
)
SELECT name, map, time, players
FROM recent_listings
WHERE players > 0
ORDER BY players DESC, name;
