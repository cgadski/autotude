import { query } from "$lib/stats.js";

export async function load({ parent }) {
  const { handleKey, handle } = await parent();

  return {
    games: await query(
      `
      SELECT *
      FROM ladder_games
      NATURAL JOIN replays
      NATURAL JOIN replays_wide
      NATURAL JOIN game_teams
      WHERE replay_key IN (
        SELECT DISTINCT replay_key
        FROM players_wide
        WHERE handle_key = ?
        AND team > 2
      )
      AND day_bin >= date('now', '-14 days', 'utc')
      ORDER BY started_at DESC
      `,
      { args: [handleKey], parse: ["teams"] },
    ),
  };
}
