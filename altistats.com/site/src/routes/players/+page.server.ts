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
        FROM time_bin_desc
        ORDER BY time_bin_desc DESC
        `,
    )
    .all();

  const res = {
    params,
    statMetas,
    timeBins,
    stat,
  };

  if (params.stat == null) {
    const players = await getStatsDb()
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
        handle: h.handle,
        stat: h.last_played,
        nicks: JSON.parse(h.nicks),
      }));

    return {
      ...res,
      players,
    };
  }

  if (stat == undefined) {
    throw error(404, `Stat ${stat} not found`);
  }

  const players = await getStatsDb()
    .prepare(
      `
        SELECT handle, stat
        FROM player_stats
        NATURAL JOIN stats
        WHERE query_name = ?
      `,
    )
    .all(stat.query_name);

  return {
    ...res,
    players,
  };
}
