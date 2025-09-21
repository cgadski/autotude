import { query } from "$lib/stats.js";

export type QueryParams = {
  period: string;
};

type TimeBin = {
  time_bin: number;
  time_bin_desc: string;
};

async function getGamesForPlayer(handleKey: number, period: string) {
  return query(
    `
    SELECT *
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN replays_wide
    NATURAL JOIN game_teams
    NATURAL JOIN time_bin_desc
    WHERE replay_key IN (
      SELECT replay_key
      FROM players_short
      WHERE handle_key = ?
    )
    AND time_bin_desc = ?
    ORDER BY started_at
    `,
    { args: [handleKey, period], parse: ["teams"] },
  );
}

export async function load({ parent, url }) {
  const { handleKey, handle } = await parent();

  const timeBins: TimeBin[] = await query(
    `SELECT time_bin, time_bin_desc FROM time_bin_desc ORDER BY time_bin DESC`,
  );

  const params: QueryParams = {
    period: url.searchParams.get("period") || timeBins[0].time_bin_desc,
  };

  const gameCountsByMonth = await query(
    `
    SELECT time_bin_desc, COUNT(*) as game_count
    FROM players_short
    NATURAL JOIN time_bin_desc
    WHERE handle_key = ?
    GROUP BY time_bin_desc
    ORDER BY time_bin DESC
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
