import pg from "pg";
import { env } from "$env/dynamic/private";
import { readFileSync } from "fs";
import { join } from "path";

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
