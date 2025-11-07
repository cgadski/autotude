WITH games_per_vapor AS (
    SELECT vapor, COUNT() AS n_games
    FROM ladder_games
    NATURAL JOIN players
    WHERE team >= 3
    GROUP BY vapor
)
SELECT handle, vapor, nick, n_games, date(max(started_at), 'unixepoch') AS last_used
FROM players
NATURAL JOIN replays
NATURAL JOIN player_key_handle
NATURAL JOIN handles
LEFT JOIN games_per_vapor USING (vapor)
GROUP BY vapor, nick
ORDER BY handle, last_used DESC;
