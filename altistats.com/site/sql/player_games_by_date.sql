SELECT
    binned_date,
    array_agg(
        json_build_object(
            'stem', stem,
            'map', map,
            'teams', teams,
            'started_at', started_at,
            'duration', duration
        )
        ORDER BY started_at DESC
    ) as games,
    COUNT(*) as game_count
FROM replays
NATURAL JOIN "4ball_games"
NATURAL JOIN teams
WHERE replay_key IN (
    SELECT replay_key
    FROM players
    WHERE vapor = $1
    AND team > 2
)
GROUP BY binned_date
ORDER BY binned_date DESC;
