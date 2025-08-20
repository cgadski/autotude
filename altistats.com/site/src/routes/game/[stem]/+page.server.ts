import { query, queryOne } from "$lib/stats";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const { stem } = params;

  return {
    game: await queryOne(
      `
      SELECT
        stem,
        map,
        teams,
        started_at,
        duration,
        winner
      FROM replays
      NATURAL JOIN replays_wide
      NATURAL JOIN game_teams
      WHERE stem = ?
      `,
      { args: [stem], parse: ["teams"] },
    ),
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
