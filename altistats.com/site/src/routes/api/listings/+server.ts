import { env } from "$env/dynamic/private";
import pg from "pg";
import { json } from "@sveltejs/kit";

const pool = new pg.Pool({
  user: env.POSTGRES_USER,
  password: env.POSTGRES_PASSWORD,
  host: env.POSTGRES_HOST,
  port: parseInt(env.POSTGRES_PORT || "5432"),
  database: env.POSTGRES_DB,
});

const LISTINGS_SQL = `
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
`;

const LISTINGS_SERIES_SQL = `
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
`;

export async function GET({ setHeaders }) {
  const [lastUpdateResult, listingsResult, listingsSeriesResult] =
    await Promise.all([
      pool.query("SELECT MAX(time) as last_update FROM listings"),
      pool.query(LISTINGS_SQL),
      pool.query(LISTINGS_SERIES_SQL),
    ]);

  setHeaders({
    "Cache-Control": "public, max-age=30",
  });

  return json({
    lastUpdate: lastUpdateResult.rows[0]?.last_update || "",
    listings: listingsResult.rows,
    listingsSeries: listingsSeriesResult.rows,
  });
}
