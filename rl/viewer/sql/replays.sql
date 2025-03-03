SELECT
    r.datetime as datetime,
    r.map as map,
    r.duration / 30 as duration_seconds,
    r.stem as stem,
    r.kills
FROM
    replays r
ORDER BY
    r.started_at DESC;
