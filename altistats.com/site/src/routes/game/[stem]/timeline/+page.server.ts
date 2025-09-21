import { query } from "$lib/stats";

export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  return {
    timeline: await query(
      `
      SELECT
        'possession' AS event_type,
        handle,
        team,
        p.start_tick AS tick,
        p.end_tick - p.start_tick AS duration
      FROM replays
      JOIN possession p USING (replay_key)
      NATURAL JOIN player_key_handle
      NATURAL JOIN handles
      JOIN players_wide USING (replay_key, handle_key)
      WHERE stem = ?
      GROUP BY p.rowid

      UNION ALL

      SELECT
        'goal' AS event_type,
        handle,
        team,
        tick,
        null AS duration
      FROM replays
      JOIN goals g USING (replay_key)
      NATURAL JOIN player_key_handle
      NATURAL JOIN handles
      WHERE stem = ?

      ORDER BY tick
      `,
      { args: [stem, stem] },
    ),
  };
}
