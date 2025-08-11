import type { StatMeta } from "$lib";
import {
  getStatsDb,
  getHandles,
  getPlayerStat,
  availableStats,
} from "$lib/stats";
import { error } from "@sveltejs/kit";

export async function load({ url }) {
  const query_name = url.searchParams.get("stat");
  const period = url.searchParams.get("period");
  const plane = url.searchParams.get("plane");

  const statMetas = await availableStats();
  const stat = statMetas.find((s) => s.query_name === query_name);

  const time_bins = await getStatsDb()
    .prepare(
      `
        SELECT time_bin, time_bin_desc
        FROM time_bin_Desc
        `,
    )
    .all();

  let res = {
    stat,
    period,
    plane,
    statMetas,
  };

  if (query_name === "none") {
    const handles = await getStatsDb()
      .prepare(
        `
          SELECT handle, nicks, started_at AS last_played
          FROM other_nicks
          NATURAL JOIN last_played
          GROUP BY handle
          ORDER BY last_played DESC
          `,
      )
      .all()
      .map((h: any) => ({
        name: h.handle,
        stat: h.last_played,
        nicks: JSON.parse(h.nicks),
      }));

    return {
      stat,
      period,
      plane,
      statMetas: statMetas,
    };
  } else {
    const orderDirection = stat.attributes.includes("reverse") ? "ASC" : "DESC";
    return getStatsDb()
      .prepare(
        `
        SELECT handle, vapor, stat
        FROM player_stats
        NATURAL JOIN handles
        NATURAL JOIN stats
        WHERE query_name = ?
        GROUP BY handle
        ORDER BY stat ${orderDirection}
        `,
      )
      .all(query_name);

    return {
      stat,
      statMetas: statMetas,
      period,
      plane,
      isNoneStat: query_name === "none",
    };
  }
}
