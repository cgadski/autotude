import { pool, loadSql } from "$lib/db";
import { getGlobalStats } from "$lib/stats";
import { type Stat } from "$lib";

export type FrontpageData = {
  lastUpdate: string;
  listings: any[];
  listingsSeries: Array<{
    bin: string;
    players: string;
  }>;
  globalStats: Stat[];
};

export async function getFrontpageData(): Promise<FrontpageData> {
  return {
    lastUpdate: "X",
    listings: [],
    listingsSeries: [],
    globalStats: await getGlobalStats(),
  };
  // return {
  //   lastUpdate: (
  //     await pool.query("SELECT MAX(time) as last_update FROM listings")
  //   ).rows[0]?.last_update,
  //   listings: (await pool.query(loadSql("listings.sql"))).rows,
  //   listingsSeries: (await pool.query(loadSql("listings_series.sql"))).rows,
  //   globalStats: await getGlobalStats(),
  // };
}
