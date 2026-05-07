-- Total kills
SELECT sum(kills)
FROM players_wide
NATURAL JOIN games
