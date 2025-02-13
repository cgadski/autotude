WITH
    kill_counts AS (
        SELECT
            replay,
            COUNT(*) as kill_count
        FROM
            kills
        GROUP BY
            replay
    )
SELECT
    stem,
    r.datetime as datetime,
    r.map as map,
    r.ticks / 30 as duration_seconds,
    r.stem as stem,
    COALESCE(k.kill_count, 0) as kills
FROM
    replays r
    LEFT JOIN kill_counts k ON r.key = k.replay
WHERE
    NOT errored
ORDER BY
    r.datetime DESC
LIMIT
    50;
