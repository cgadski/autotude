SELECT * FROM replays
NATURAL JOIN "4ball_games"
WHERE binned_date = $1::date
ORDER BY started_at DESC;
