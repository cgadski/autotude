import { queryOne } from "$lib/stats";
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
  };
}
