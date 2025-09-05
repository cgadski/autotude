import { query } from "$lib/stats";

export async function load({ setHeaders }) {
  return {
    gameTimestamps: await query(
      `
      SELECT started_at, duration, day_bin
      FROM ladder_games
      NATURAL JOIN replays
      NATURAL JOIN replays_wide
      WHERE day_bin >= date('now', '-90 days')
      ORDER BY started_at
      `,
    ),
  };
}
