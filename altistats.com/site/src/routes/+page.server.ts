import { loadSql, pool } from "$lib/db";
import { getGlobalStats, getRecentGames } from "$lib/stats";
import { type Stat } from "$lib";
import { getStatsDb } from "$lib/stats";

export type FrontpageData = {
  lastUpdate: string;
  listings: any[];
  listingsSeries: Array<{
    bin: string;
    players: string;
  }>;
  globalStats: Stat[];
  recentGames: any[];
};

export async function load(): Promise<FrontpageData> {
  let recentGames = await getStatsDb()
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
        LIMIT 5
        `,
    )
    .all()
    .map((game: any) => ({
      ...game,
      teams: JSON.parse(game.teams),
    }));

  return {
    lastUpdate: "",
    listings: [],
    listingsSeries: [],
    globalStats: await getGlobalStats(),
    recentGames,
  };

  return {
    lastUpdate: (
      await pool.query("SELECT MAX(time) as last_update FROM listings")
    ).rows[0]?.last_update,
    listings: (await pool.query(loadSql("listings.sql"))).rows,
    listingsSeries: (await pool.query(loadSql("listings_series.sql"))).rows,
    globalStats: await getGlobalStats(),
    recentGames: await getRecentGames(),
  };
}
