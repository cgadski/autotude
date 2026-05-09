-- Total data
WITH
totals AS (
    SELECT
        sum(bytes) AS bytes_total,
        sum(bytes) FILTER (WHERE replay_key IN (SELECT replay_key FROM games)) AS bytes_games
    FROM replays
)
SELECT printf('%.2fG (%.2fG are games)', sum(bytes_total)/1000000000., sum(bytes_games)/1000000000.)
FROM totals
