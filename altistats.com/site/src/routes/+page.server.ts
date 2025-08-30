import { query } from "$lib/stats";

export async function load({ setHeaders }) {
  return {
    globalStats: await query(
      `
      SELECT query_name, description, stat
      FROM global_stats
      NATURAL JOIN stats
      ORDER BY query_name
    `,
    ),
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
