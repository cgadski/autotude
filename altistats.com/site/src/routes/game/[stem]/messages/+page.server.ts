import { query } from "$lib/stats";

export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  return {
    messages: await query(
      `
      SELECT
        tick,
        chat_message,
        handle,
        player_key
      FROM messages
      NATURAL JOIN replays
      LEFT JOIN player_key_handle USING (replay_key, player_key)
      LEFT JOIN handles USING (handle_key)
      WHERE stem = ?
      ORDER BY tick
      `,
      { args: [stem] },
    ),
  };
}
