-- Total players
SELECT count(DISTINCT name)
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN handles
WHERE team > 2
