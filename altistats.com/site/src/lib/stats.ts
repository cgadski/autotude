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

export function playersUrl(props: any) {
  return;
}

export async function getGlobalStats(): Promise<Array<Stat>> {
  return getStatsDb()
    .prepare(
      `
    SELECT query_name, description, stat, attributes
    FROM global_stats
    NATURAL JOIN stats
    WHERE time_bin is NULL
    ORDER BY query_name
  `,
    )
    .all();
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

export async function getHandles(): Promise<
  Array<{
    handle: string;
    nicks: string[];
    last_played: number;
  }>
> {
  return getStatsDb()
    .prepare(
      `
      SELECT handle, nicks, started_at AS last_played
      FROM other_nicks
      NATURAL JOIN last_played
      GROUP BY handle
      ORDER BY last_played DESC
      `,
    )
    .all();
}

export async function getPlayerGames(name: string): Promise<any[]> {
  const db = getStatsDb();

  const games = db
    .prepare(
      `
      WITH
      my_games AS (
      SELECT
        DISTINCT replay_key
        FROM ladder_games NATURAL JOIN players NATURAL JOIN handles
        WHERE handle = ? AND team > 2
      )
      SELECT
        stem,
        map,
        teams,
        started_at,
        duration,
        winner
      FROM game_teams
      NATURAL JOIN my_games
      NATURAL JOIN game_meta
      ORDER BY started_at DESC
      LIMIT 10
      `,
    )
    .all(name);

  return games.map((game) => ({
    ...game,
    teams: JSON.parse(game.teams),
  }));
}

export async function getRecentGames(): Promise<any[]> {
  return getStatsDb()
    .prepare(
      `
      SELECT
        stem,
        map,
        teams,
        started_at,
        duration,
        winner
      FROM game_teams
      NATURAL JOIN ladder_games
      NATURAL JOIN game_meta
      ORDER BY started_at DESC
      LIMIT 10
      `,
    )
    .all()
    .map((game) => ({
      ...game,
      teams: JSON.parse(game.teams),
    }));
}

export async function getGame(stem: string): Promise<any | null> {
  const db = getStatsDb();

  const game = db
    .prepare(
      `
      SELECT
        gt.stem,
        gt.map,
        gt.teams,
        gt.started_at,
        gt.duration,
        gm.winner
      FROM game_teams gt
      LEFT JOIN game_meta gm ON gm.replay_key = gt.replay_key
      WHERE gt.stem = ?
      `,
    )
    .get(stem);

  if (!game) return null;

  return {
    ...game,
    teams: JSON.parse(game.teams),
  };
}
