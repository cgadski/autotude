-- Total players
-- EXPLAIN QUERY PLAN
SELECT
    count(DISTINCT handle_key)
FROM handles
NATURAL JOIN players_handles
NATURAL JOIN ladder_games
WHERE team > 2
