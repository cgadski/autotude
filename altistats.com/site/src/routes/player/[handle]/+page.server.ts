import { query } from "$lib/stats.js";

export type QueryParams = {
  period: string;
};

type TimeBin = {
  time_bin_key: number;
  time_bin: string;
};

async function getGamesForPlayer(handleKey: number, period: string) {
  return query(
    `
    SELECT *
    FROM games
    NATURAL JOIN replays
    NATURAL JOIN replays_wide
    WHERE replay_key IN (
      SELECT replay_key
      FROM players_short
      WHERE handle_key = ?
    )
    AND time_bin = ?
    ORDER BY started_at
    `,
    { args: [handleKey, period], parse: ["teams"] },
  );
}

export async function load({ parent, url }) {
  const { handleKey, handle } = await parent();

  const timeBins: TimeBin[] = await query(
    `SELECT time_bin_key, time_bin FROM time_bins ORDER BY time_bin DESC`,
  );

  const params: QueryParams = {
    period: url.searchParams.get("period") || timeBins[0].time_bin,
  };

  const gameCountsByMonth = await query(
    `
    SELECT time_bin, COUNT(*) as game_count
    FROM players_short
    NATURAL JOIN time_bins
    WHERE handle_key = ?
    GROUP BY time_bin_key
    ORDER BY time_bin_key DESC
    `,
    { args: [handleKey] },
  );

  return {
    params: { ...params },
    timeBins,
    games: await getGamesForPlayer(handleKey, params.period),
    gameCountsByMonth,
  };
}
