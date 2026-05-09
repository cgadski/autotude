SELECT stem, map, datetime(started_at, 'unixepoch'), server, next_key, prev_key
FROM replays r
LEFT JOIN replays_wide rw USING (replay_key)
WHERE (
    (rw.replay_key is null OR rw.next_key is null)
    AND server != ''
)
