WITH
agg_data AS (
SELECT
    vapor,
    MAX(started_at) as last_seen,
    array_agg(DISTINCT nick) AS nicks
    FROM players
    NATURAL JOIN replays
    GROUP BY vapor
)

SELECT
    vapor,
    games,
    nicks,
    last_seen
FROM agg_data
JOIN games_per_player USING (vapor)
WHERE games > 0
ORDER BY games DESC;
