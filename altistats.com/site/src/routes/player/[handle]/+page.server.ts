import { query } from "$lib/stats.js";

export async function load({ params }) {
  const handle = params.handle;

  return {
    handle: params.handle,
    nicks: (
      await query(
        `
        SELECT nicks
        FROM handles
        NATURAL JOIN handle_nicks
        WHERE handle = ?
        `,
        { args: [handle], parse: ["nicks"] },
      )
    )[0].nicks,
    stats: await query(
      `
      SELECT query_name, description, stat, attributes
      FROM player_stats
      NATURAL JOIN stats
      NATURAL JOIN handles
      WHERE handle = ?
      AND plane is null
      AND time_bin is null
      ORDER BY stat DESC
    `,
      { args: [handle], parse: ["attributes"] },
    ),
    games: await query(
      `
      WITH player_games AS (
        SELECT DISTINCT replay_key
        FROM ladder_games
        NATURAL JOIN replays
        NATURAL JOIN players_wide
        NATURAL JOIN handles
        WHERE handle = ? AND team > 2
      )
      SELECT started_at, map, stem, duration, winner, teams
      FROM player_games
      NATURAL JOIN replays
      NATURAL JOIN replays_wide
      NATURAL JOIN game_teams
      ORDER BY started_at DESC
      LIMIT 20
      `,
      { args: [handle], parse: ["teams"] },
    ),
  };
}
