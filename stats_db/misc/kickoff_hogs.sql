WITH
game_tbl AS (
    SELECT * FROM replays NATURAL JOIN games WHERE series_key = 0
),
touch_ranks AS (
    SELECT
        replay_key, map, handle_key, team, start_tick,
        row_number() OVER (PARTITION BY replay_key ORDER BY start_tick) AS rank
    FROM game_tbl
    NATURAL JOIN possession
    NATURAL JOIN players
    NATURAL JOIN player_key_handle
),
kickoff_stats AS (
    SELECT handle_key, COUNT() AS n_kickoffs FROM touch_ranks
    WHERE rank = 1
    GROUP BY handle_key
),
games_per_player AS (
    SELECT handle_key, COUNT() AS n_games
    FROM game_tbl
    NATURAL JOIN players
    NATURAL JOIN player_key_handle
    WHERE team >= 3
    GROUP BY handle_key
),
stats AS (
    SELECT
        handle_key, n_games, n_kickoffs,
        CAST(n_kickoffs AS REAL) / n_games AS prop
    FROM games_per_player
    LEFT JOIN kickoff_stats USING (handle_key)
)
SELECT
    handle, n_games, n_kickoffs,
    printf('%.2f', prop) AS prop
FROM stats
NATURAL JOIN handles
ORDER BY stats.prop DESC;
