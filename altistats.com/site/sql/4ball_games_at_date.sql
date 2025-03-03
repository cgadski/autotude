SELECT * FROM replays
NATURAL JOIN "4ball_games"
NATURAL JOIN teams
WHERE binned_date = $1::date
ORDER BY started_at DESC;
