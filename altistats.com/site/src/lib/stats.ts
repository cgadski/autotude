import Database from "better-sqlite3";
import { env } from "$env/dynamic/private";
import type { Stat, StatMeta } from ".";

let statsDb: Database.Database | null = null;

export function getStatsDb(): Database.Database {
  if (!statsDb) {
    const dbPath = env.STATS_DB;
    if (!dbPath) {
      throw new Error("STATS_DB environment variable not set");
    }
    statsDb = new Database(dbPath, { readonly: true });
  }
  return statsDb;
}

export async function query(
  queryStr: string,
  options: {
    args?: any[];
    parse?: string[];
  } = {},
) {
  const { args = [], parse: parsedColumns = [] } = options;
  return getStatsDb()
    .prepare(queryStr)
    .all(...args)
    .map((row: any) => {
      parsedColumns.forEach((column) => {
        if (row[column]) {
          row[column] = JSON.parse(row[column]);
        }
      });
      return row;
    });
}

export async function queryOne(
  queryStr: string,
  options: {
    args?: any[];
    parse?: string[];
  } = {},
) {
  return (await query(queryStr, options))[0];
}

export async function availableStats(): Promise<Array<StatMeta>> {
  return getStatsDb()
    .prepare(
      `
      SELECT DISTINCT query_name, description, attributes
      FROM stats
      WHERE stat_key IN (
        SELECT DISTINCT stat_key
        FROM player_stats
      )
      ORDER BY query_name
      `,
    )
    .all()
    .map((row: any) => ({
      ...row,
      attributes: JSON.parse(row.attributes),
    }));
}
