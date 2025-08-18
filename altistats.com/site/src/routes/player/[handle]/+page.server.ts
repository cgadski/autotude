import { query, queryOne } from "$lib/stats.js";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const handle = params.handle;
  console.log({ handle: handle });
  const handleKey = (
    await query(
      `
    SELECT handle_key FROM handles WHERE handle = ?
    `,
      { args: [handle] },
    )
  )[0]?.handle_key;

  if (handleKey === null) {
    throw error(404, `Handle ${handle} not found.`);
  }

  return {
    handle: params.handle,
    lastPlayed: (
      await queryOne(
        `
      SELECT last_played FROM last_played
      WHERE handle_key = ?
      `,
        { args: [handleKey] },
      )
    )?.last_played,
    nicks: (
      await queryOne(
        `
        SELECT nicks
        FROM handle_nicks
        WHERE handle_key = ?
        `,
        { args: [handleKey], parse: ["nicks"] },
      )
    ).nicks,
    stats: await query(
      `
      SELECT query_name, description, stat, attributes
      FROM player_stats
      NATURAL JOIN stats
      WHERE handle_key = ?
      AND plane is null
      AND time_bin is null
      ORDER BY stat DESC
    `,
      { args: [handleKey], parse: ["attributes"] },
    ),
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
