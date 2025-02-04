WITH
    ladder_games AS (
        SELECT
            *
        FROM
            replays
        WHERE
            map LIKE "ball_4%"
            AND ticks >= 2 * 60 * 30 -- at least 2 minutes
            AND NOT EXISTS ( -- no bots
                SELECT
                    1
                FROM
                    players p
                WHERE
                    p.replay_id = replays.replay_id
                    AND p.name LIKE "Bot%"
            )
    ),
    player_counts AS (
        SELECT
            replay_id,
            COUNT() AS n_players
        FROM
            ladder_games
            NATURAL JOIN players
        GROUP BY
            replay_id
    ),
    filtered_games AS (
        SELECT
            *
        FROM
            ladder_games
            NATURAL JOIN player_counts
        WHERE
            n_players >= 8
        ORDER BY
            time DESC
        LIMIT
            500
    )
SELECT
    replay_id,
    time,
    map,
    path,
    ticks,
    JSON_GROUP_ARRAY (JSON_ARRAY (name, team)) AS players
FROM
    filtered_games
    NATURAL JOIN players
GROUP BY
    replay_id
ORDER BY
    time DESC;
