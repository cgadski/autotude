import { query } from "$lib/stats";

export type QueryParams = {
  period: string | null;
};

type TimeBin = {
  time_bin: number;
  time_bin_desc: string;
};

async function getGamesForPeriod(timeBinIndex: number | null) {
  if (timeBinIndex === null) {
    return [];
  }

  return query(
    `
    SELECT *
      FROM ladder_games
      NATURAL JOIN replays_wide
      NATURAL JOIN replays
      NATURAL JOIN game_teams
      WHERE time_bin = ?
      ORDER BY started_at
    `,
    { args: [timeBinIndex], parse: ["teams"] },
  );
}

export async function load({ url }) {
  const timeBins: TimeBin[] = await query(
    `SELECT time_bin, time_bin_desc FROM time_bin_desc ORDER BY time_bin DESC`,
  );

  const params: QueryParams = {
    period:
      url.searchParams.get("period") || timeBins[0]?.time_bin_desc || null,
  };

  const timeBinIndex = params.period
    ? timeBins.find((tb) => tb.time_bin_desc === params.period)?.time_bin
    : null;

  const gameCountsByMonth = await query(
    `
    SELECT time_bin_desc, COUNT(*) as game_count
    FROM replays_wide
    NATURAL JOIN ladder_games
    NATURAL JOIN time_bin_desc
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
  };
}
