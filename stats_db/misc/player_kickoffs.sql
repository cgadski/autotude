WITH
touch_ranks AS (
    SELECT
        replay_key, map, name, team, start_tick,
        row_number() OVER (PARTITION BY replay_key ORDER BY start_tick) AS rank
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN possession
    NATURAL JOIN players
    JOIN handles USING (vapor)
),
goal_ranks AS (
    SELECT
        replay_key, map, team,
        row_number() OVER (PARTITION BY replay_key ORDER BY tick) AS rank
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN goals
    NATURAL JOIN players
),
player_stats AS (
    SELECT
        name,
        count() AS n_games,
        count() FILTER (WHERE touch_ranks.team = goal_ranks.team) AS n_team_scored
    FROM touch_ranks
    JOIN goal_ranks USING (replay_key)
    WHERE touch_ranks.rank = 1
    AND goal_ranks.rank = 1
    GROUP BY name ORDER BY n_games desc
),
z_stat AS (
    SELECT
        *,
        (CAST(n_team_scored AS REAL) / n_games) AS empirical_prob,
        (n_team_scored - n_games * 0.5) / SQRT(0.25 * n_games) AS z_stat
    FROM player_stats
)
SELECT
    name, n_games, n_team_scored,
    printf('%.2f', empirical_prob) AS empirical_prob,
    printf('%.2f', z_stat) AS z_stat
FROM z_stat
WHERE n_games > 35
ORDER BY z_stat.z_stat DESC;
