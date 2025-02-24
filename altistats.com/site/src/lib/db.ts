import pg from "pg";
import { env } from "$env/dynamic/private";
import { readFileSync } from "fs";
import { join } from "path";

export type Game = {
  started_at: string;
  map: string;
  stem: string;
  duration: number;
  teams: {
    [key: string]: Array<{
      nick: string;
      vapor: string;
    }>;
  };
};

const pool = new pg.Pool({
  user: env.POSTGRES_USER,
  password: env.POSTGRES_PASSWORD,
  host: env.POSTGRES_HOST,
  port: parseInt(env.POSTGRES_PORT || "5432"),
  database: env.POSTGRES_DB,
});

export async function getLastUpdate() {
  const result = await pool.query(
    "SELECT MAX(time) as last_update FROM listings",
  );
  return result.rows[0]?.last_update;
}

const SQL_DIR =
  process.env.NODE_ENV === "production"
    ? "/app/sql"
    : join(process.cwd(), "sql");

function loadSql(filename: string): string {
  return readFileSync(join(SQL_DIR, filename), "utf-8");
}

export async function getRecentListings() {
  const result = await pool.query(loadSql("listings.sql"));
  return result.rows;
}

export async function getRecentGames(limit = 30): Promise<Game[]> {
  const result = await pool.query(loadSql("4ball_games.sql"), [limit]);
  return result.rows;
}

export type Totals = {
  n_vapors: number;
  n_replays: number;
  hours: number;
};

export async function getTotals(): Promise<Totals> {
  const result = await pool.query("SELECT * FROM mv_totals");
  return result.rows[0];
}

export async function getGame(stem: string): Promise<Game | null> {
  const result = await pool.query(
    `SELECT started_at, map, stem, teams
     FROM replays
     NATURAL JOIN teams
     WHERE stem = $1`,
    [stem],
  );
  return result.rows[0] || null;
}
