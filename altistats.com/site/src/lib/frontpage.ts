import { pool, loadSql } from "$lib/db";
import { getGlobalStats, type GlobalStat } from "$lib/stats";

export type FrontpageData = {
  lastUpdate: string;
  listings: any[];
  listingsSeries: Array<{
    bin: string;
    players: string;
  }>;
  globalStats: GlobalStat[];
};

export async function getFrontpageData(): Promise<FrontpageData> {
  return {
    lastUpdate: (
      await pool.query("SELECT MAX(time) as last_update FROM listings")
    ).rows[0]?.last_update,
    listings: (await pool.query(loadSql("listings.sql"))).rows,
    listingsSeries: (await pool.query(loadSql("listings_series.sql"))).rows,
    globalStats: await getGlobalStats(),
  };
}
