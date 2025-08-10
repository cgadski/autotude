import { error } from "@sveltejs/kit";
import { getPlayerGames } from "$lib/stats";
import { getPlayerNames, getStatsForPlayer } from "$lib/stats.js";

export async function load({ params }) {
  const vapor = params.vapor;

  let names = await getPlayerNames(vapor);
  const games = await getPlayerGames(names.name);

  return {
    name: names.name,
    nicks: names.nicks,
    stats: await getStatsForPlayer(names.name),
    games,
  };
}
