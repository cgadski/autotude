-- Total players
SELECT count(DISTINCT handle_key)
FROM ladder_games
NATURAL JOIN players_wide
WHERE team > 2
