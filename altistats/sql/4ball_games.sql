WITH
active_players AS (
    SELECT replay_key, COUNT(*) AS n
    FROM replays r
    NATURAL JOIN players p
    WHERE team > 2
    GROUP BY replay_key
),
no_bots AS (
    SELECT replay_key FROM replays r
    WHERE NOT EXISTS (
        SELECT 1 FROM players p
        WHERE p.replay_key = r.replay_key
        AND p.nick LIKE 'Bot %'
    )
)

SELECT started_at, map, stem, teams FROM replays
NATURAL JOIN active_players
NATURAL JOIN no_bots
NATURAL JOIN teams
WHERE map != 'lobby_4ball'
AND n >= 8
ORDER BY started_at DESC
LIMIT $1;
