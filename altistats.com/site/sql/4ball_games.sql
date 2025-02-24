SELECT * FROM replays
NATURAL JOIN "4ball_games"
NATURAL JOIN teams
ORDER BY started_at DESC
LIMIT $1;
