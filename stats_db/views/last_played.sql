DROP VIEW IF EXISTS last_played;
CREATE VIEW last_played AS
SELECT handle_key, max(replays.started_at) AS last_played
FROM players_wide
NATURAL JOIN replays
GROUP BY handle_key;
