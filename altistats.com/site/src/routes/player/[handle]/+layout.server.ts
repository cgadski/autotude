import { query, queryOne, queryValue } from "$lib/stats.js";
import { error } from "@sveltejs/kit";

export async function load({ params }) {
  const handle = params.handle;
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
    handleKey,
    lastPlayed: await queryValue(
      `
      SELECT last_played FROM last_played
      WHERE handle_key = ?
      `,
      { args: [handleKey] },
    ),
    nicks: await queryValue(
      `
        SELECT nicks
        FROM handle_nicks
        WHERE handle_key = ?
        `,
      { args: [handleKey], parse: ["nicks"] },
    ),
    nPlayed: await queryValue(
      `
      SELECT
        (count() FILTER (WHERE won))
        || '#G won : '
        || (count() FILTER (WHERE not won))
        || '#R lost'
      FROM players_short
      WHERE handle_key = ?
      `,
      { args: [handleKey] },
    ),
    nKills: await queryValue(
      `
      SELECT
        sum(kills)
        || '#G : '
        || sum(deaths)
        || '#R'
      FROM players_wide
      WHERE handle_key = ?
      `,
      { args: [handleKey] },
    ),
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
  };
}
