import { error } from "@sveltejs/kit";
import { getPlayerGames } from "$lib/stats";
import { getStatsDb } from "$lib/stats.js";
import type { Stat } from "$lib";

async function getStatsForPlayer(name: string): Promise<Stat[]> {
  return getStatsDb()
    .prepare(
      `
    SELECT query_name, description, stat, attributes
    FROM player_stats
    NATURAL JOIN stats
    WHERE handle = ?
    ORDER BY stat DESC
    `,
    )
    .all(name);
}

async function getPlayerNames(handle: string): Promise<any> {
  const result = getStatsDb()
    .prepare(
      `
    SELECT
      vapor,
      handle,
      nicks
      FROM other_nicks
      WHERE handle = ?
  `,
    )
    .get(handle);

  return {
    vapor: result.vapor,
    name: result.handle,
    nicks: JSON.parse(result.nicks),
  };
}

export async function load({ params }) {
  const vapor = params.handle;

  let names = await getPlayerNames(vapor);
  const games = await getPlayerGames(names.name);

  return {
    name: names.name,
    nicks: names.nicks,
    stats: await getStatsForPlayer(names.name),
    games,
  };
}
