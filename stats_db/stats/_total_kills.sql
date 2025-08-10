-- Total kills
SELECT
    time_bin,
    count() AS stat
FROM kills
NATURAL JOIN ladder_games
NATURAL JOIN time_bins
WHERE who_killed IS NOT null
