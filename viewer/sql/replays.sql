WITH
    kill_counts AS (
        SELECT
            replay,
            COUNT(*) as kill_count
        FROM
            kills
        GROUP BY
            replay
    ),
    player_counts AS (
        SELECT
            replay_key,
            COUNT() as player_count
        FROM
            players
        GROUP BY
            replay_key
    )
SELECT
    r.datetime as datetime,
    r.map as map,
    r.ticks / 30 as duration_seconds,
    r.stem as stem,
    COALESCE(k.kill_count, 0) as kills,
    COALESCE(p.player_count, 0) as players
FROM
    replays r
    LEFT JOIN kill_counts k ON r.key = k.replay
    LEFT JOIN player_counts p ON r.key = p.replay_key
WHERE
    NOT errored
ORDER BY
    r.datetime DESC;
