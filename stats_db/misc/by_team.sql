WITH
game_tbl AS (
    SELECT map, winner
    FROM replays NATURAL JOIN replays_wide NATURAL JOIN games WHERE series_key = 0
    UNION ALL
    SELECT 'ball_*', winner
    FROM replays_wide NATURAL JOIN games WHERE series_key = 0
),
total_games AS (
    SELECT map, COUNT() as ct
    FROM game_tbl
    GROUP BY map
)
SELECT
    map AS map,
    COUNT() FILTER (WHERE winner = 3) AS left_wins,
    COUNT() FILTER (WHERE winner = 4) AS right_wins,
    COUNT() AS games,
    printf('%.2f', CAST(COUNT() FILTER (WHERE winner = 3) AS REAL) / COUNT()) AS win_rate,
    printf('%.2f', (CAST(COUNT() FILTER (WHERE winner = 3) AS REAL) / COUNT() - 0.5) /
    SQRT(0.25 / COUNT())) AS z_statistic
FROM game_tbl
JOIN total_games USING (map)
GROUP BY map
ORDER BY total_games.ct DESC;
