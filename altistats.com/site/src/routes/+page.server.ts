import {
  getRecentListings,
  getLastUpdate,
  getRecentGames,
  getTotals,
} from "$lib/db";

export async function load() {
  return {
    lastUpdate: await getLastUpdate(),
    listings: await getRecentListings(),
    games: await getRecentGames(),
    totals: await getTotals(),
  };
}
