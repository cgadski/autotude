import { query } from "$lib/stats";

export type HistoryData = {
  selectedStat: string;
  periodBreakdown: Array<{
    time_bin: string | null;
    time_bin_desc: string | null;
    stat: number;
  }>;
  availableStats: Array<{
    query_name: string;
    description: string;
    attributes: string[];
    total: number;
  }>;
};

export async function load({ params }) {
  return {
    globalStats: await query(
      `
      SELECT query_name, description, stat, attributes
      FROM global_stats
      NATURAL JOIN stats
      ORDER BY query_name
    `,
      { parsed: ["attributes"] },
    ),
  };
}

// export async function load({ url }): Promise<HistoryData> {
//   const globalStats = await getGlobalStats();
//   const availableStats = getStatsDb()
//     .prepare(
//       `
//       SELECT DISTINCT query_name, description, attributes
//       FROM stats
//       NATURAL JOIN global_stats
//       ORDER BY query_name
//       `,
//     )
//     .all()
//     .map((row: any) => {
//       const globalStat = globalStats.find(
//         (gs) => gs.query_name === row.query_name,
//       );
//       return {
//         ...row,
//         attributes: JSON.parse(row.attributes),
//         total: globalStat?.stat || 0,
//       };
//     });

//   const selectedStat =
//     url.searchParams.get("stat") ||
//     availableStats[0]?.query_name ||
//     "_total_games";

//   // Get period breakdown for the selected stat using materialized stats
//   const periodBreakdownQuery = `
//     SELECT
//       time_bin,
//       time_bin_desc,
//       stat
//     FROM global_stats
//     NATURAL JOIN stats
//     LEFT JOIN time_bin_desc USING (time_bin)
//     WHERE query_name = ?
//       AND time_bin IS NOT NULL
//     ORDER BY time_bin ASC
//   `;

//   const periodBreakdown = getStatsDb()
//     .prepare(periodBreakdownQuery)
//     .all(selectedStat);

//   return {
//     selectedStat,
//     periodBreakdown,
//     availableStats,
//   };
// }
