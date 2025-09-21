import { query, queryOne } from "$lib/stats";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const { stem } = params;

  const game = await queryOne(
    `
    SELECT
      stem,
      map,
      teams,
      started_at,
      duration,
      version,
      winner,
      stem IN (SELECT stem FROM broken_replays) AS broken
    FROM replays
    NATURAL JOIN replays_wide
    NATURAL JOIN game_teams
    WHERE stem = ?
    `,
    { args: [stem], parse: ["teams"] },
  );

  if (!game) {
    throw error(404, "Game not found");
  }

  return {
    game,
    stem,
  };
}
