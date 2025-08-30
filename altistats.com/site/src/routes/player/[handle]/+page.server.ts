import { query } from "$lib/stats.js";

export async function load({ parent }) {
  const { handleKey } = await parent();

  return {
    activity: await query(
      `
      SELECT time_bin_desc, plane, n_games, n_won
      FROM monthly_activity
      NATURAL JOIN time_bin_desc
      WHERE handle_key = ?
      ORDER BY time_bin DESC, plane
      `,
      { args: [handleKey] },
    ),
    months: await query(`SELECT time_bin_desc FROM time_bin_desc`),
  };
}
