import { query } from "$lib/stats.js";

export async function load({ parent }) {
  const { handleKey } = await parent();

  return {
    activity: await query(
      `
      SELECT time_bin, plane, n_games, n_won
      FROM monthly_activity
      NATURAL JOIN time_bins
      WHERE handle_key = ?
      ORDER BY time_bin DESC, plane
      `,
      { args: [handleKey] },
    ),
    months: await query(`SELECT time_bin FROM time_bins`),
  };
}
