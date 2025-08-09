SELECT map, COUNT() as n_games
FROM replays
NATURAL JOIN ladder_games
GROUP BY map
ORDER BY n_games DESC;
