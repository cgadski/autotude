import { query } from "$lib/stats";

export async function load({ setHeaders }) {
  return {
    handles: (
      await query(
        "SELECT DISTINCT handle FROM handles NATURAL JOIN players_wide",
      )
    ).map((h) => h.handle),
    recentGames: await query(
      `
      SELECT *
        FROM ladder_games
        NATURAL JOIN replays_wide
        NATURAL JOIN replays
        NATURAL JOIN game_teams
        WHERE day_bin >= date('now', '-7 days', 'utc')
        ORDER BY started_at
      `,
      { parse: ["teams"] },
    ),
  };
}
