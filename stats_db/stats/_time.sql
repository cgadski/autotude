-- Total game time
-- attributes: duration
SELECT sum(duration) AS stat
FROM ladder_games
NATURAL JOIN replays
