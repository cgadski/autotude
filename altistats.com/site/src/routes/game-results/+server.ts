import { query } from "$lib/stats";

export async function GET({ url }) {
  const series: number = url.searchParams.has("series")
    ? parseInt(url.searchParams.get("series")!)
    : 3;

  const rows = await query(
    `
    SELECT
      datetime(started_at + tick / 30.0, 'unixepoch') AS t,
      server AS server,
      map,
      chat_message AS announcement
    FROM games
    NATURAL JOIN replays
    NATURAL JOIN messages
    WHERE series_key = ?
    AND (
      chat_message LIKE '% wins the map %'
      OR chat_message LIKE 'draw %'
    )
    ORDER BY started_at, tick
    `,
    { args: [series] },
  );

  const body =
    rows
      .map((r: any) => [r.t, r.server, r.map, r.announcement].join("\t"))
      .join("\n") + "\n";

  return new Response(body, {
    headers: { "content-type": "text/plain; charset=utf-8" },
  });
}
