WITH
n_players AS (
    SELECT r.key AS key, COUNT() AS n FROM replays r
    JOIN players p ON (p.replay_key = r.key)
    GROUP BY r.key
),
no_bots AS (
    SELECT key FROM replays r
    WHERE NOT EXISTS (
        SELECT 1 FROM players p
        WHERE p.replay_key = r.key
        AND p.nick LIKE 'Bot %'
    )
)

SELECT path FROM replays
JOIN n_players USING (key)
JOIN no_bots USING (key)
WHERE map LIKE 'ball_4%' AND NOT errored
AND n >= 8
ORDER BY datetime;
