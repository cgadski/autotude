-- Total messages
SELECT
    time_bin, count()
FROM messages
NATURAL JOIN time_bins
WHERE player_key IS NOT NULL
GROUP BY time_bin
