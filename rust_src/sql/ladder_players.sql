WITH games_per_player AS (
    SELECT vapor, COUNT() AS n_games
    FROM ladder_games
    NATURAL JOIN players
    WHERE team >= 3
    GROUP BY vapor
)
SELECT vapor, nick
FROM players
NATURAL JOIN replays
JOIN games_per_player USING (vapor)
GROUP BY vapor, nick
ORDER BY n_games DESC;
