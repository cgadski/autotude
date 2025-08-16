import { json } from "@sveltejs/kit";
import { query, queryOne } from "$lib/stats";
import type { RequestHandler } from "./$types";

export const GET: RequestHandler = async ({ params }) => {
  const { stem } = params;

  return json(
    await queryOne(
      `
      SELECT stem, map, started_at, teams, winner
      FROM replays
      NATURAL JOIN replays_wide
      NATURAL JOIN game_teams
      WHERE stem = ?
    `,
      { args: [stem], parse: ["teams"] },
    ),
  );
};
