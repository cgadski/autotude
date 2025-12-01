import { query } from "$lib/stats";

export async function load({ params, parent }) {
  const { stem } = params;
  await parent();

  // Get block boundaries (goals and sudden death messages)
  const blockBoundaries = await query(
    `
    SELECT tick, 'goal' as type, team, handle
    FROM replays
    JOIN goals USING (replay_key)
    NATURAL JOIN player_key_handle
    NATURAL JOIN handles
    WHERE stem = ?

    UNION ALL

    SELECT tick, 'sudden_death' as type, null as team, null as handle
    FROM replays
    JOIN messages USING (replay_key)
    WHERE stem = ?
    AND player_key IS NULL
    AND chat_message LIKE 'Sudden Death:%'

    ORDER BY tick
    `,
    { args: [stem, stem] },
  );

  // Get all possession data
  const possessions = await query(
    `
    SELECT
      p.start_tick,
      p.end_tick,
      pw.team,
      p.end_tick - p.start_tick as duration
    FROM replays
    JOIN possession p USING (replay_key)
    JOIN players_wide pw ON (
      pw.replay_key = p.replay_key
      AND pw.player_key = p.player_key
      AND p.start_tick >= pw.start_tick
      AND (pw.end_tick IS NULL OR p.start_tick < pw.end_tick)
    )
    WHERE stem = ?
    ORDER BY p.start_tick
    `,
    { args: [stem] },
  );

  // Get all kills
  const kills = await query(
    `
    SELECT
      k.tick,
      pw_killer.team as killer_team,
      pw_victim.team as victim_team
    FROM replays
    JOIN kills k USING (replay_key)
    JOIN players_wide pw_killer ON (
      pw_killer.replay_key = k.replay_key
      AND pw_killer.player_key = k.who_killed
      AND k.tick >= pw_killer.start_tick
      AND (pw_killer.end_tick IS NULL OR k.tick < pw_killer.end_tick)
    )
    JOIN players_wide pw_victim ON (
      pw_victim.replay_key = k.replay_key
      AND pw_victim.player_key = k.who_died
      AND k.tick >= pw_victim.start_tick
      AND (pw_victim.end_tick IS NULL OR k.tick < pw_victim.end_tick)
    )
    WHERE stem = ?
    ORDER BY k.tick
    `,
    { args: [stem] },
  );

  // Get all messages
  const messages = await query(
    `
    SELECT
      tick,
      'message' as type,
      chat_message,
      handle,
      player_key,
      team
    FROM messages
    NATURAL JOIN replays
    LEFT JOIN player_key_handle USING (replay_key, player_key)
    LEFT JOIN handles USING (handle_key)
    LEFT JOIN players USING (replay_key, player_key)
    WHERE stem = ?
    `,
    { args: [stem] },
  );

  // Create blocks with possession data
  const blocks = [];
  let blockStart = 0;

  for (let i = 0; i < blockBoundaries.length; i++) {
    const boundary = blockBoundaries[i];
    const blockEnd = boundary.tick;

    // Calculate possession for this block
    let team3Duration = 0;
    let team4Duration = 0;

    for (const poss of possessions) {
      const possStart = Math.max(poss.start_tick, blockStart);
      const possEnd = Math.min(poss.end_tick, blockEnd);

      if (possStart < possEnd) {
        const duration = possEnd - possStart;
        if (poss.team === 3) {
          team3Duration += duration;
        } else if (poss.team === 4) {
          team4Duration += duration;
        }
      }
    }

    // Calculate kills for this block
    let team3Kills = 0;
    let team4Kills = 0;

    for (const kill of kills) {
      if (kill.tick >= blockStart && kill.tick < blockEnd) {
        if (kill.killer_team === 3) team3Kills++;
        if (kill.killer_team === 4) team4Kills++;
      }
    }

    blocks.push({
      tick: blockEnd,
      type: "block_end",
      endType: boundary.type,
      endTeam: boundary.team,
      endHandle: boundary.handle,
      team3Duration,
      team4Duration,
      team3Kills,
      team4Kills,
    });

    blockStart = blockEnd;
  }

  // Combine messages and blocks, sort by tick
  const timelineItems = [...messages, ...blocks].sort(
    (a, b) => a.tick - b.tick,
  );

  const parentData = await parent();

  return {
    timelineItems,
    game: parentData.game,
    stem: parentData.stem,
  };
}
