import type { StatMeta } from "$lib";
import { getStatsDb, getHandles, availableStats } from "$lib/stats";
import { error } from "@sveltejs/kit";

export type QueryParams = {
  stat: string | null;
  period: string | null;
  plane: string | null;
};

export async function load({ url }) {
  const params: QueryParams = {
    stat: url.searchParams.get("stat") || null,
    period: url.searchParams.get("period") || null,
    plane: url.searchParams.get("plane") || null,
  };

  // Get all available stats
  const statMetas = await availableStats();
  const stat = statMetas.find((s) => s.query_name === params.stat);

  const timeBins = await getStatsDb()
    .prepare(
      `
        SELECT time_bin, time_bin_desc
        FROM time_bin_Desc
        `,
    )
    .all();

  return {
    params,
    statMetas,
    timeBins,
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
