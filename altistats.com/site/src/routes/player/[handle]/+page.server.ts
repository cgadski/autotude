import { query } from "$lib/stats.js";
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
    nicks: (
      await query(
        `
        SELECT nicks
        FROM handle_nicks
        WHERE handle_key = ?
        `,
        { args: [handleKey], parse: ["nicks"] },
      )
    )[0].nicks,
    timeAlive: await query(
      `
      SELECT plane, sum(time_alive) AS time_alive
      FROM time_alive
      WHERE handle_key = ?
      GROUP BY plane
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
    gamesByDay: await query(
      `
      WITH
      days AS (
        SELECT date('now', '-12 hours', '-' || column1 || ' days', 'utc') as day_bin
        FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22))
      ),
      player_games AS (
        SELECT replay_key, started_at, stem, day_bin, winner, team, duration
        FROM ladder_games
        NATURAL JOIN replays
        NATURAL JOIN replays_wide
        NATURAL JOIN players_wide
        WHERE handle_key = ?
        AND team > 2
        AND day_bin IN days
        GROUP BY replay_key
      ),
      games_by_day AS (
        SELECT day_bin,
          json_group_array(
            json_object(
              'stem', stem,
              'winner', winner,
              'playerTeam', team
            )
          ) AS games,
          sum(duration) AS time
        FROM (
          SELECT * FROM player_games
          WHERE day_bin IN days
          ORDER BY day_bin, started_at
        )
        GROUP BY day_bin
      )
      SELECT day_bin,
        coalesce(games, json_array()) AS games,
        time
      FROM days LEFT JOIN games_by_day USING (day_bin)
      `,
      { args: [handleKey], parse: ["games"] },
    ),
  };
}
