import type { StatMeta } from "$lib";
import { getStatsDb, getHandles, availableStats, query } from "$lib/stats";
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

  const statMetas = await availableStats();
  const stat = statMetas.find((s) => s.query_name === params.stat);

  const timeBins: Array<{ time_bin: number; time_bin_desc: string }> =
    await query(
      `
        SELECT time_bin, time_bin_desc
        FROM time_bin_desc
        ORDER BY time_bin_desc DESC
        `,
    );

  const res = {
    params,
    statMetas,
    timeBins,
    stat,
  };

  if (params.stat == null) {
    return {
      ...res,
      players: await query(
        `
          SELECT handle, nicks, max(started_at) AS last_played
          FROM players_wide
          NATURAL JOIN ladder_games
          JOIN replays USING (replay_key)
          JOIN handle_nicks USING (handle_key)
          JOIN handles USING (handle_key)
          WHERE team > 2
          GROUP BY handle_key
          ORDER BY last_played DESC
        `,
        {
          parse: ["nicks"],
        },
      ),
    };
  }

  if (stat == undefined) {
    throw error(404, `Stat ${stat} not found`);
  }

  const timeBinIndex = params.period
    ? timeBins.find((tb) => tb.time_bin_desc === params.period)?.time_bin
    : null;

  const planes = ["loopy", "bomber", "whale", "biplane", "miranda"];
  const planeIndex = params.plane
    ? planes.findIndex((p) => p === params.plane)
    : null;

  const planeCondition = planeIndex !== null ? "plane = ?" : "plane IS NULL";
  const timeBinCondition =
    timeBinIndex !== null ? "time_bin = ?" : "time_bin IS NULL";

  const statReversed = stat.attributes.includes("reverse") ? "ASC" : "DESC";

  const args: any[] = [params.stat];
  if (planeIndex !== null) args.push(planeIndex);
  if (timeBinIndex !== null) args.push(timeBinIndex);

  return {
    ...res,
    timeBinIndex,
    players: await query(
      `
        SELECT handle, stat, detail
        FROM player_stats
        NATURAL JOIN stats
        NATURAL JOIN handles
        WHERE query_name = ?
        AND ${planeCondition}
        AND ${timeBinCondition}
        ORDER BY stat ${statReversed}
      `,
      {
        args,
      },
    ),
  };
}
