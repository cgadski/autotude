WITH goal_possessions AS (
    SELECT
        g.replay_key,
        g.player_key,
        g.tick,
        g.tick - p.end_tick AS flight_time,
        ROW_NUMBER() OVER (
            PARTITION BY g.replay_key, g.tick
            ORDER BY p.end_tick DESC
        ) as rn
    FROM goals g
    JOIN ladder_games ON g.replay_key = ladder_games.replay_key
    JOIN possession p ON g.replay_key = p.replay_key
        AND p.end_tick - 30 <= g.tick
)
SELECT
    ROW_NUMBER() OVER (ORDER BY flight_time DESC) AS rank,
    'http://altistats.com/viewer/?f=' || stem || '.pb&t=' || (tick - flight_time - 30) AS url,
    handle,
    ROUND(flight_time / 30.0, 1) AS seconds
FROM goal_possessions
JOIN replays USING (replay_key)
JOIN player_key_handle USING (replay_key, player_key)
JOIN handles USING (handle_key)
WHERE rn = 1
ORDER BY flight_time DESC
LIMIT 50;
