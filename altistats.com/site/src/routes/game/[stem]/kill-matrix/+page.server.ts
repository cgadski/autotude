import { query } from "$lib/stats";

export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  const players = await query(
    `
    SELECT handle, team
    FROM players_short ps
    JOIN handles h USING (handle_key)
    JOIN replays r USING (replay_key)
    WHERE r.stem = ?
    ORDER BY team, handle
    `,
    { args: [stem] },
  );

  const killMatrix = await query(
    `
    SELECT
      kh.handle as killer_handle,
      vh.handle as victim_handle,
      COUNT(*) as kill_count
    FROM kills k
    JOIN replays r USING (replay_key)
    JOIN player_key_handle kpkh ON (k.replay_key = kpkh.replay_key AND k.who_killed = kpkh.player_key)
    JOIN player_key_handle vpkh ON (k.replay_key = vpkh.replay_key AND k.who_died = vpkh.player_key)
    JOIN handles kh ON (kpkh.handle_key = kh.handle_key)
    JOIN handles vh ON (vpkh.handle_key = vh.handle_key)
    WHERE r.stem = ?
    GROUP BY kh.handle_key, vh.handle_key
    `,
    { args: [stem] },
  );

  return {
    players,
    killMatrix,
  };
}
