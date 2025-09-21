import { query } from "$lib/stats";

export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  return {
    players: await query(
      `
      SELECT
        handle,
        team,
        plane
      FROM players_short
      NATURAL JOIN handles
      NATURAL JOIN replays
      WHERE stem = ?
      ORDER BY team, handle
      `,
      { args: [stem] },
    ),
  };
}
