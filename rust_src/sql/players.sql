WITH vapor_idx AS (
    SELECT vapor, row_number() OVER (ORDER BY vapor) AS idx
    FROM players
    WHERE vapor != ''
    GROUP BY vapor
),
games_per_player AS (
    SELECT vapor, COUNT() AS n_games
    FROM ladder_games
    NATURAL JOIN players
    WHERE team >= 3
    GROUP BY vapor
)
SELECT idx % 2, vapor, nick, n_games, date(max(started_at), 'unixepoch') AS last_used
FROM players
NATURAL JOIN replays
JOIN vapor_idx USING (vapor)
LEFT JOIN games_per_player USING (vapor)
GROUP BY vapor, nick
ORDER BY idx, last_used DESC;
