SELECT 
    vapor,
    array_agg(DISTINCT nick) AS nicks,
    (array_agg(DISTINCT nick))[1] AS nick,
    COUNT(*) FILTER (WHERE team > 2) as games,
    COUNT(DISTINCT binned_date) as days_played,
    MAX(started_at) as last_seen
FROM players
NATURAL JOIN "4ball_games"
NATURAL JOIN replays
WHERE vapor = $1
GROUP BY vapor;
