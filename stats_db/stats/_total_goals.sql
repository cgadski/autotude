-- Total goals
SELECT count() AS stat
FROM goals
NATURAL JOIN ladder_games
