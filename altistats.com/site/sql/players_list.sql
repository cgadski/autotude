SELECT
    vapor,
    array_agg(DISTINCT nick) AS nicks,
    COUNT(*) FILTER (WHERE team > 2) as games,
    MAX(started_at) as last_seen
FROM players
NATURAL JOIN "4ball_games"
NATURAL JOIN replays
GROUP BY vapor
ORDER BY games DESC
LIMIT 100;
