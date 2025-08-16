import { query } from "$lib/stats";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const { stem } = params;

  return {
    game: await query(
      `
      SELECT
        gt.stem,
        gt.map,
        gt.teams,
        gt.started_at,
        gt.duration,
        gm.winner
      FROM game_teams gt
      LEFT JOIN replays_wide gm ON gm.replay_key = gt.replay_key
      WHERE gt.stem = ?
      `,
      { args: [stem] },
    ),
  };
}
