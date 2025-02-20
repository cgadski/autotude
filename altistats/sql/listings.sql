WITH recent_listings AS (
    SELECT DISTINCT ON (name)
        time,
        name,
        map,
        players,
        pw_required,
        version,
        hardcore,
        ping
    FROM listings
    ORDER BY name, time DESC
)
SELECT *
FROM recent_listings
WHERE players > 0
ORDER BY players DESC, name;
