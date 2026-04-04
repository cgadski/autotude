import { query } from "$lib/stats.js";
import { planes } from "$lib";

export async function load({ parent }) {
  const { handleKey } = await parent();

  const rows: any[] = await query(
    `
    WITH ranked AS (
      SELECT
        stat_key,
        handle_key,
        plane,
        stat,
        repr,
        hidden,
        rank() OVER (
          PARTITION BY stat_key, plane
          ORDER BY CASE WHEN s.attributes LIKE '%reverse%' THEN stat ELSE -stat END
        ) AS rank,
        count() OVER (PARTITION BY stat_key, plane) AS total
      FROM player_stats
      JOIN stats_raw s USING (stat_key)
      WHERE time_bin IS NULL AND NOT hidden
    )
    SELECT
      query_name, description, attributes, plane, stat, repr, rank, total, 0 AS hidden, stat_order
    FROM ranked
    NATURAL JOIN stats
    WHERE handle_key = ?

    UNION ALL

    SELECT
      s.query_name, s.description, s.attributes, ps.plane, NULL, NULL, NULL, NULL, 1 AS hidden, s.stat_order
    FROM player_stats ps
    NATURAL JOIN stats s
    WHERE ps.time_bin IS NULL AND ps.hidden AND ps.handle_key = ?

    ORDER BY stat_order, plane
    `,
    { args: [handleKey, handleKey], parse: ["attributes"] },
  );

  const grouped = new Map<string, any>();
  for (const row of rows) {
    if (!grouped.has(row.query_name)) {
      grouped.set(row.query_name, {
        query_name: row.query_name,
        description: row.description,
        reverse: (row.attributes || []).includes("reverse"),
        overall: null,
        planes: new Map<number, any>(),
      });
    }
    const entry = grouped.get(row.query_name)!;
    const item = {
      repr: row.repr,
      stat: row.stat,
      rank: row.rank,
      total: row.total,
      plane: row.plane,
      hidden: !!row.hidden,
    };
    if (row.plane === null) {
      entry.overall = item;
    } else {
      entry.planes.set(row.plane, { ...item, planeName: planes[row.plane] });
    }
  }

  const stats = [...grouped.values()]
    .filter((s) => s.overall && !s.overall.hidden)
    .map((s) => ({
      ...s,
      planes: planes.map((name, i) =>
        s.planes.has(i)
          ? s.planes.get(i)
          : { plane: i, planeName: name, hidden: true },
      ),
    }));

  return { stats };
}
