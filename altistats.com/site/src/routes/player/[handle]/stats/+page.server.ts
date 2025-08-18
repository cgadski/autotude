import { query, queryOne } from "$lib/stats.js";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const handle = params.handle;
  const handleKey = (
    await query(
      `
    SELECT handle_key FROM handles WHERE handle = ?
    `,
      { args: [handle] },
    )
  )[0]?.handle_key;

  if (handleKey === null) {
    throw error(404, `Handle ${handle} not found.`);
  }

  return {
    handle: params.handle,
    timeAliveByMonth: await query(
      `
      WITH monthly_totals AS (
        SELECT
          time_bin_desc,
          sum(time_alive) as total_time
        FROM time_alive
        NATURAL JOIN time_bin_desc
        WHERE handle_key = ?
        GROUP BY time_bin_desc
      ),
      planes AS (
        SELECT 0 as plane UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
      ),
      month_plane_combinations AS (
        SELECT mt.time_bin_desc, p.plane, mt.total_time
        FROM monthly_totals mt
        CROSS JOIN planes p
      ),
      base_data AS (
        SELECT
          mpc.time_bin_desc,
          mpc.plane,
          coalesce(ta.time_alive, 0) as time_alive,
          mpc.total_time
        FROM month_plane_combinations mpc
        LEFT JOIN time_alive ta ON (
          ta.handle_key = ?
          AND ta.time_bin = (SELECT time_bin FROM time_bin_desc WHERE time_bin_desc = mpc.time_bin_desc)
          AND ta.plane = mpc.plane
        )
      ),
      max_time AS (
        SELECT MAX(time_alive) as max_single_value
        FROM base_data
      )
      SELECT
        bd.time_bin_desc,
        bd.plane,
        bd.time_alive,
        bd.total_time,
        CASE
          WHEN mt.max_single_value > 0 THEN CAST(bd.time_alive AS REAL) / mt.max_single_value
          ELSE 0
        END as scaled_proportion
      FROM base_data bd
      CROSS JOIN max_time mt
      ORDER BY bd.time_bin_desc DESC, bd.plane
      `,
      { args: [handleKey, handleKey] },
    ),
  };
}
