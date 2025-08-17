SELECT
r.stem,
map,
teams
-- started_at,
-- duration,
-- winner
FROM replays r
JOIN replays_wide USING (replay_key)
NATURAL JOIN game_teams
WHERE r.stem = '815900b1-55a5-435e-8409-afd7ce18df59'
