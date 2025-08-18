import { query } from "$lib/stats";

export type FrontpageData = {
  recentGames: any[];
};

export async function load({ setHeaders }): Promise<FrontpageData> {
  let recentGames = await query(
    `
      SELECT
        stem,
        map,
        teams,
        started_at,
        duration,
        winner
      FROM replays
      NATURAL JOIN ladder_games
      NATURAL JOIN replays_wide
      NATURAL JOIN game_teams
      ORDER BY started_at DESC
      LIMIT 20
    `,
    { parse: ["teams"] },
  );

  setHeaders({
    "Cache-Control": "public, max-age=30",
  });

  return {
    recentGames,
  };
}
