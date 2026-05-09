DROP VIEW IF EXISTS monthly_activity;
CREATE VIEW monthly_activity AS
SELECT
    handle_key, r.time_bin_key, plane,
    count() AS n_games,
    count() FILTER (WHERE winner = team) AS n_won
FROM players_short
JOIN replays_wide r USING (replay_key)
GROUP BY handle_key, r.time_bin_key, plane;
