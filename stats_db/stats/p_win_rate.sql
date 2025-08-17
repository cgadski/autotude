-- Win rate
WITH tbl AS (
    SELECT
        handle_key,
        replays_wide.time_bin,
        plane,
        cast(count() AS real) AS n_games ,
        cast(count() FILTER (WHERE winner = team) AS real) AS n_wins
    FROM (SELECT * FROM players_wide GROUP BY replay_key, handle_key)
    JOIN ladder_games USING (replay_key)
    JOIN replays_wide USING (replay_key)
    WHERE team > 2
    GROUP BY handle_key, replays_wide.time_bin, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(n_wins) / sum(n_games) AS stat,
    format("%.2f", sum(n_wins) / sum(n_games))
    || ' | ' || sum(n_wins) || '/' || sum(n_games) AS repr,
    sum(n_games) < 100 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(n_wins) / sum(n_games) AS stat,
    format("%.2f", sum(n_wins) / sum(n_games))
    || ' | ' || sum(n_wins) || '/' || sum(n_games) AS repr,
    sum(n_games) < 25 AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(n_wins) / sum(n_games) AS stat,
    format("%.2f", sum(n_wins) / sum(n_games))
    || ' | ' || sum(n_wins) || '/' || sum(n_games) AS repr,
    sum(n_games) < 50 AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    0 AS stat,
    'stat' AS repr,
    false AS hidden
FROM tbl
