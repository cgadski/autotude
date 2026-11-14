import { query } from "$lib/stats";

export async function GET({ url }) {
  const series: number = url.searchParams.has("series")
    ? parseInt(url.searchParams.get("series")!)
    : 3;

  const rows = await query(
    `
    SELECT
      datetime(started_at + tick / 30.0, 'unixepoch') AS timestamp,
      coalesce(handle, 'server') AS handle,
      chat_message AS message,
      map,
      stem
    FROM games
    NATURAL JOIN messages
    NATURAL JOIN replays
    LEFT JOIN player_key_handle USING (replay_key, player_key)
    LEFT JOIN handles USING (handle_key)
    WHERE series_key = ?
    ORDER BY started_at, tick
    `,
    { args: [series] },
  );

  const body =
    rows
      .map((r: any) =>
        [r.timestamp, r.handle, r.message, r.map, r.stem].join("\t"),
      )
      .join("\n") + "\n";

  return new Response(body, {
    headers: { "content-type": "text/plain; charset=utf-8" },
  });
}
