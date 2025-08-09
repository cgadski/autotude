WITH
touch_ranks AS (
    SELECT
        replay_key, map, name, team, start_tick,
        row_number() OVER (PARTITION BY replay_key ORDER BY start_tick) AS rank
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN possession
    NATURAL JOIN players
    JOIN names USING (vapor)
),
kickoff_stats AS (
    SELECT name, COUNT() AS n_kickoffs FROM touch_ranks
    WHERE rank = 1
    GROUP BY name
),
games_per_player AS (
    SELECT name, COUNT() AS n_games
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN players
    NATURAL JOIN names
    WHERE team >= 3
    GROUP BY name
),
stats AS (
    SELECT
        name, n_games, n_kickoffs,
        CAST(n_kickoffs AS REAL) / n_games AS prop
    FROM games_per_player
    LEFT JOIN kickoff_stats USING (name)
)
SELECT
    name, n_games, n_kickoffs,
    printf('%.2f', prop) AS prop
FROM stats
ORDER BY stats.prop DESC;
