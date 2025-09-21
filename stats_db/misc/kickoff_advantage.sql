WITH
touch_ranks AS (
    SELECT
        replay_key, map, team, start_tick,
        row_number() OVER (PARTITION BY replay_key ORDER BY start_tick) AS rank
    FROM ladder_games
    NATURAL JOIN replays
    NATURAL JOIN possession
    NATURAL JOIN players
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
touch_outcomes AS (
    SELECT
        goal_ranks.map,
        goal_ranks.team AS scoring_team,
        touch_ranks.team AS touching_team
    FROM touch_ranks
    JOIN goal_ranks USING (replay_key)
    WHERE touch_ranks.rank = 1
    AND goal_ranks.rank = 1
),
map_stats AS (
    SELECT
        map,
        COUNT() AS n_games,
        COUNT() FILTER (WHERE scoring_team = touching_team) AS n_touch_scored
    FROM touch_outcomes
    GROUP BY map
    ORDER BY n_games DESC
),
z_stat AS (
SELECT
    *,
    (n_touch_scored - n_games * 0.547) / SQRT(0.25 * n_games) AS z_stat
FROM map_stats
)
SELECT
    map, n_games, n_touch_scored,
    printf('%.2f', z_stat) AS z_stat
FROM z_stat
ORDER BY z_stat.z_stat DESC;
