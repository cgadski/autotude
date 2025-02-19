import pg from "pg";
import { env } from "$env/dynamic/private";

const pool = new pg.Pool({
  user: env.POSTGRES_USER,
  password: env.POSTGRES_PASSWORD,
  host: env.POSTGRES_HOST,
  port: parseInt(env.POSTGRES_PORT || "5432"),
  database: env.POSTGRES_DB,
});

export async function getRecentListings() {
  const result = await pool.query(
    `WITH recent_listings AS (
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
        ORDER BY players DESC, name;`,
  );
  return result.rows;
}
