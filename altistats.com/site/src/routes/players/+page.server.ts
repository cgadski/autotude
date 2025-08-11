import { getPlayerStat, availablePlayerStats } from "$lib/stats";
import { error } from "@sveltejs/kit";

export async function load({ url }) {
  const query_name = url.searchParams.get("stat") || "p_goal_rate";
  const statTypes = await availablePlayerStats();
  const stat = statTypes.find((s) => s.query_name === query_name);
  if (stat == undefined) {
    throw error(404, "Stat query does not exist");
  }
  const players = await getPlayerStat(query_name, stat.attributes);

  return {
    players,
    statTypes,
    stat: stat,
  };
}
