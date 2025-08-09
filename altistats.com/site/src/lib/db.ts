import pg from "pg";
import Database from "better-sqlite3";
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

export const pool = new pg.Pool({
  user: env.POSTGRES_USER,
  password: env.POSTGRES_PASSWORD,
  host: env.POSTGRES_HOST,
  port: parseInt(env.POSTGRES_PORT || "5432"),
  database: env.POSTGRES_DB,
});

const SQL_DIR =
  process.env.NODE_ENV === "production"
    ? "/app/sql"
    : join(process.cwd(), "sql");

export function loadSql(filename: string): string {
  return readFileSync(join(SQL_DIR, filename), "utf-8");
}

export type CalendarEntry = {
  date: string;
  count: number;
};

export async function getReplayCalendar(): Promise<CalendarEntry[]> {
  const result = await pool.query(loadSql("replay_calendar.sql"));
  console.log("Calendar query result:", result.rows);
  return result.rows;
}

export async function getGame(stem: string): Promise<Game | null> {
  const result = await pool.query(
    `SELECT started_at, map, stem, teams, duration
     FROM replays
     NATURAL JOIN teams
     WHERE stem = $1`,
    [stem],
  );
  return result.rows[0] || null;
}

export async function getRecentGames(limit = 10): Promise<Game[]> {
  const result = await pool.query(loadSql("4ball_games.sql"), [limit]);
  return result.rows;
}

export async function gamesForDate(date: string): Promise<Game[]> {
  const result = await pool.query(loadSql("4ball_games_at_date.sql"), [date]);
  return result.rows;
}

export async function getPlayersList(): Promise<any[]> {
  const result = await pool.query(loadSql("players_list.sql"));
  return result.rows;
}

export async function getPlayerInfo(vapor: string): Promise<any> {
  const result = await pool.query(loadSql("player_info.sql"), [vapor]);
  return result.rows[0] || null;
}

export async function getPlayerGamesByDate(vapor: string): Promise<any[]> {
  const result = await pool.query(loadSql("player_games_by_date.sql"), [vapor]);
  return result.rows;
}
