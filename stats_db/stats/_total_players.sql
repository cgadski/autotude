-- Total players
SELECT
    time_bin,
    count(DISTINCT handle)
FROM ladder_games
NATURAL JOIN time_bins
NATURAL JOIN players
NATURAL JOIN handles
WHERE team > 2
GROUP BY time_bin
UNION
SELECT
    NULL as time_bin,
    count(DISTINCT handle)
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN handles
