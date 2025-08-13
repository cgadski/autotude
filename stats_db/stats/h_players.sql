SELECT
    time_bin,
    count(DISTINCT handle_key)
FROM handles
NATURAL JOIN players_handles
NATURAL JOIN ladder_games
NATURAL JOIN time_bins
GROUP BY time_bin
UNION ALL
SELECT
    null AS time_bin,
    count(DISTINCT handle_key)
FROM players_handles
NATURAL JOIN ladder_games
