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
      points_left,
      points_right,
      stem IN (SELECT stem FROM broken_replays) AS broken,
      series_key,
      series_name
    FROM replays
    NATURAL JOIN replays_wide
    NATURAL JOIN game_teams
    NATURAL JOIN games
    NATURAL JOIN series_desc
    WHERE stem = ?
    `,
    { args: [stem], parse: ["teams"] },
  );

  if (!game) {
    throw error(404, "Game not found");
  }

  const players = await query(
    `
    SELECT
      h.handle,
      ps.team,
      gs.kills,
      gs.deaths,
      gs.goals,
      gs.points,
      gs.red_perk,
      gs.green_perk,
      gs.blue_perk,
      gs.pos
    FROM game_stats gs
    JOIN handles h USING (handle_key)
    JOIN players_short ps USING (replay_key, handle_key)
    WHERE gs.replay_key = (SELECT replay_key FROM replays WHERE stem = ?)
    ORDER BY ps.team, h.handle
    `,
    { args: [stem] },
  );

  return {
    game,
    stem,
    players,
  };
}
