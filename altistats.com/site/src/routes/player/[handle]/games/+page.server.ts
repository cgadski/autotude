import { query } from "$lib/stats.js";

export type QueryParams = {
  period: string | null;
};

type TimeBin = {
  time_bin: number;
  time_bin_desc: string;
};

async function getGamesForPlayer(
  handleKey: number,
  timeBinIndex: number | null,
) {
  const timeCondition = timeBinIndex !== null ? "AND time_bin = ?" : "";
  const args = [handleKey];
  if (timeBinIndex !== null) {
    args.push(timeBinIndex);
  }

  return query(
    `
    SELECT *
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN replays_wide
    NATURAL JOIN game_teams
    WHERE replay_key IN (
      SELECT DISTINCT replay_key
      FROM players_wide
      WHERE handle_key = ?
      AND team > 2
    )
    ${timeCondition}
    ORDER BY started_at DESC
    `,
    { args, parse: ["teams"] },
  );
}

export async function load({ parent, url }) {
  const { handleKey, handle } = await parent();

  const params: QueryParams = {
    period: url.searchParams.get("period") || null,
  };

  const timeBins: TimeBin[] = await query(
    `SELECT time_bin, time_bin_desc FROM time_bin_desc ORDER BY time_bin DESC`,
  );

  const timeBinIndex = params.period
    ? timeBins.find((tb) => tb.time_bin_desc === params.period)?.time_bin
    : timeBins[0]?.time_bin || null;

  const selectedPeriod = params.period || timeBins[0]?.time_bin_desc || null;

  return {
    params: { ...params, period: selectedPeriod },
    timeBins,
    games: await getGamesForPlayer(handleKey, timeBinIndex),
  };
}
