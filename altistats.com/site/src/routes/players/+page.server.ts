import { planes as planeList, type StatMeta } from "$lib";
import { getStatsDb, playerStats, query } from "$lib/stats";
import { error } from "@sveltejs/kit";

export type QueryParams = {
  stat: string | null;
  period: string | null;
  plane: string | null;
};

type TimeBin = {
  time_bin_key: number;
  time_bin: string;
};

async function getPlayerStats(
  params: QueryParams,
  timeBins: TimeBin[],
  statAttributes: string[],
) {
  const timeBinIndex = params.period
    ? timeBins.find((tb) => tb.time_bin === params.period)?.time_bin_key
    : null;

  const planeIndex = params.plane
    ? planeList.findIndex((p) => p === params.plane)
    : null;

  const planeCondition = planeIndex !== null ? "plane = ?" : "plane IS NULL";
  const timeBinCondition =
    timeBinIndex !== null ? "time_bin_key = ?" : "time_bin_key IS NULL";

  const statReversed = statAttributes.includes("reverse") ? "ASC" : "DESC";

  const args: any[] = [params.stat];
  if (planeIndex !== null) args.push(planeIndex);
  if (timeBinIndex !== null) args.push(timeBinIndex);

  return query(
    `
      SELECT handle, stat, repr
      FROM player_stats
      NATURAL JOIN stats
      NATURAL JOIN handles
      WHERE query_name = ?
      AND ${planeCondition}
      AND ${timeBinCondition}
      AND NOT hidden
      ORDER BY stat ${statReversed}
    `,
    { args },
  );
}

export async function load({ url }) {
  const params: QueryParams = {
    stat: url.searchParams.get("stat") || null,
    period: url.searchParams.get("period") || null,
    plane: url.searchParams.get("plane") || null,
  };

  const statMetas = await playerStats();
  const stat = statMetas.find((s) => s.query_name === params.stat);

  const timeBins: TimeBin[] = await query(
    "SELECT * FROM time_bins ORDER BY time_bin DESC",
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
          SELECT handle, nicks, last_played,
                 datetime('now') >= datetime(last_played, 'unixepoch', '+48 hours') as is_older
          FROM last_played
          NATURAL JOIN handle_nicks
          NATURAL JOIN handles
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

  return {
    ...res,
    playerStats: await getPlayerStats(params, timeBins, stat.attributes),
  };
}
