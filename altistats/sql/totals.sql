WITH
vapor_totals AS (
    SELECT count(distinct vapor) AS n_vapors
    FROM replays
    NATURAL JOIN "4ball_games"
    NATURAL JOIN players
),
replay_totals AS (
    SELECT count(*) AS n_replays,
    round(sum(duration)::float / 30 / 60 / 60) AS hours
    FROM replays
    NATURAL JOIN "4ball_games"
)
SELECT *
FROM vapor_totals
CROSS JOIN replay_totals;
