import Database from "better-sqlite3";
import { env } from "$env/dynamic/private";
import type { Stat } from ".";

let statsDb: Database.Database | null = null;

function getStatsDb(): Database.Database {
  if (!statsDb) {
    const dbPath = env.STATS_DB;
    if (!dbPath) {
      throw new Error("STATS_DB environment variable not set");
    }
    statsDb = new Database(dbPath, { readonly: true });
  }
  return statsDb;
}

export async function getGlobalStats(): Promise<Stat[]> {
  const db = getStatsDb();

  const stats = db
    .prepare(
      `
    SELECT query_name, description, stat, attributes
    FROM global_stats
    NATURAL JOIN stats
    ORDER BY query_name
  `,
    )
    .all() as Stat[];

  return stats;
}
