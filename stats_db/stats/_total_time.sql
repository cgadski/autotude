-- Gameplay time
-- duration
SELECT time_bin, sum(duration)
FROM ladder_games
NATURAL JOIN replays
NATURAL JOIN time_bins
