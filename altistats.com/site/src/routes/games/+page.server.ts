import { query } from "$lib/stats";
import { error } from "@sveltejs/kit";

export type QueryParams = {
  series: number;
  period: string | null;
};

type TimeBin = {
  time_bin_key: number;
  time_bin: string;
};

async function getGamesForPeriod(seriesKey: number, timeBinKey: number) {
  return query(
    `
    SELECT *
      FROM games
      NATURAL JOIN replays_wide
      NATURAL JOIN replays
      NATURAL JOIN game_teams
      WHERE series_key = ?
      AND time_bin_key = ?
      ORDER BY started_at
    `,
    { args: [seriesKey, timeBinKey], parse: ["teams"] },
  );
}

export async function load({ url }) {
  const series: number = url.searchParams.get("series")
    ? parseInt(url.searchParams.get("series")!)
    : 0;

  const timeBins: TimeBin[] = await query(
    `
    SELECT time_bin, time_bin_key, count() AS ct
    FROM replays_wide JOIN games USING (replay_key)
    WHERE series_key = ?
    GROUP BY time_bin, time_bin_key
    HAVING ct > 0
    ORDER BY time_bin DESC
    `,
    { args: [series] },
  );

  const params = {
    series: series,
    period: url.searchParams.get("period") || timeBins[0]?.time_bin || null,
  };

  const timeBinKey: number | undefined = params.period
    ? timeBins.find((tb) => tb.time_bin === params.period)?.time_bin_key
    : undefined;

  if (timeBinKey === undefined) {
    error(404, { message: `No period found for ${params.period}` });
  }

  return {
    params,
    timeBins,
    series: await query(
      "SELECT series_key, series_name, series_desc FROM series_desc",
    ),
    handles: (
      await query(
        "SELECT DISTINCT handle FROM handles NATURAL JOIN players_wide",
      )
    ).map((h: any) => h.handle),
    games: await getGamesForPeriod(params.series, timeBinKey),
    gameCountsByMonth: await query(
      `
      SELECT time_bin, COUNT(*) as game_count
      FROM replays_wide
      NATURAL JOIN games
      WHERE series_key = ?
      GROUP BY time_bin
      ORDER BY time_bin DESC
      `,
      { args: [params.series] },
    ),
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
