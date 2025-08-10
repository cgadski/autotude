-- Total goals
SELECT
    time_bin,
    count() AS stat
FROM goals
NATURAL JOIN ladder_games
NATURAL JOIN time_bins
GROUP BY time_bin
