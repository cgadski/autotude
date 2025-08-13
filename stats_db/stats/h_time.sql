-- Total time
-- duration
SELECT
    time_bin,
    sum(duration) AS stat
FROM ladder_games
NATURAL JOIN time_bins
NATURAL JOIN replays
GROUP BY time_bin
