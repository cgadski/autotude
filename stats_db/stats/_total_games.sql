-- Ranked games
SELECT
    time_bin,
    count() AS stat
FROM ladder_games
NATURAL JOIN time_bins
GROUP BY time_bin
