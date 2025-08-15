SELECT
    time_bin,
    count(DISTINCT handle_key)
FROM ladder_games
NATURAL JOIN players_wide
NATURAL JOIN replays_wide
GROUP BY time_bin
UNION ALL
SELECT
    null AS time_bin,
    count(DISTINCT handle_key)
FROM ladder_games
NATURAL JOIN players_wide
WHERE team > 2
