import { query } from "$lib/stats";

export type QueryParams = {
  period: string | null;
};

type TimeBin = {
  time_bin_key: number;
  time_bin: string;
};

async function getGamesForPeriod(timeBinIndex: number | undefined) {
  if (timeBinIndex === undefined) {
    return [];
  }

  return query(
    `
    SELECT *
      FROM games
      NATURAL JOIN replays_wide
      NATURAL JOIN replays
      NATURAL JOIN game_teams
      WHERE time_bin_key = ?
      ORDER BY started_at
    `,
    { args: [timeBinIndex], parse: ["teams"] },
  );
}

export async function load({ url }) {
  const timeBins: TimeBin[] = await query(
    `SELECT time_bin, time_bin_key FROM time_bins ORDER BY time_bin DESC`,
  );

  const params: QueryParams = {
    period: url.searchParams.get("period") || timeBins[0]?.time_bin || null,
  };

  const timeBinIndex: number | undefined = params.period
    ? timeBins.find((tb) => tb.time_bin === params.period)?.time_bin_key
    : undefined;

  const gameCountsByMonth = await query(
    `
    SELECT time_bin, COUNT(*) as game_count
    FROM replays_wide
    NATURAL JOIN games
    GROUP BY time_bin
    ORDER BY time_bin DESC
    `,
  );

  return {
    params,
    timeBins,
    handles: (
      await query(
        "SELECT DISTINCT handle FROM handles NATURAL JOIN players_wide",
      )
    ).map((h) => h.handle),
    games: await getGamesForPeriod(timeBinIndex),
    gameCountsByMonth,
    globalStats: await query(
      `
      SELECT query_name, description, stat
      FROM stats
      NATURAL JOIN global_stats
      ORDER BY stat_order
    `,
    ),
  };
}
