WITH
    recent_games AS (
        SELECT
            r.key,
            r.stem,
            r.map,
            r.datetime,
            r.ticks::float / 30 / 60 as minutes,
            COUNT(DISTINCT p.key) as player_count
        FROM replays r
        LEFT JOIN players p ON p.replay_key = r.key
        WHERE r.ticks >= 30 * 30  -- at least 30 seconds
        GROUP BY r.key, r.stem, r.map, r.datetime, r.ticks
        ORDER BY r.datetime DESC
        LIMIT 5
    ),
    player_teams AS (
        SELECT DISTINCT ON (p.key)
            g.key as replay_key,
            p.key as player_key,
            p.nick,
            p.ticks_alive,
            p.team
        FROM recent_games g
        JOIN players p ON p.replay_key = g.key
        ORDER BY p.key, p.ticks_alive DESC
    )
SELECT
    g.key as replay_key,
    g.stem,
    g.map,
    g.datetime,
    ROUND(g.minutes::numeric, 1) as minutes,
    g.player_count,
    json_group_array(
        json_object(
            'nick', pt.nick,
            'team', pt.team,
            'ticks_alive', pt.ticks_alive
        )
    ) as players
FROM recent_games g
LEFT JOIN player_teams pt ON pt.replay_key = g.key
GROUP BY g.key, g.stem, g.map, g.datetime, g.minutes, g.player_count
ORDER BY g.datetime DESC;
