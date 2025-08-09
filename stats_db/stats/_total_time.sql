-- Gameplay time
-- duration
SELECT sum(duration) FROM ladder_games
NATURAL JOIN replays
