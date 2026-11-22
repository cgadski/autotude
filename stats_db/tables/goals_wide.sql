BEGIN;

DROP TABLE IF EXISTS goals_wide;

CREATE TABLE IF NOT EXISTS goals_wide (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    tick INTEGER,
    team INTEGER,
    points INTEGER
);

CREATE INDEX IF NOT EXISTS idx_goals_wide ON goals (replay_key, tick);

INSERT INTO goals_wide
WITH goal_spans AS (
    SELECT replay_key, player_key, team, tick,
        coalesce(
            lead(tick) OVER (PARTITION BY replay_key, team ORDER BY tick),
            999999999999
        ) AS window_end
    FROM goals
),
-- last score update before a goal
score_before AS (
    SELECT replay_key, team, goal_tick, points, upd_tick
    FROM (
        SELECT g.replay_key, g.team, g.tick AS goal_tick,
            s.points, s.tick AS upd_tick,
            row_number() OVER (
                PARTITION BY g.replay_key, g.team, g.tick
                ORDER BY s.tick DESC, s.rowid DESC
            ) AS rn
        FROM goal_spans g
        JOIN scores s
            ON s.replay_key = g.replay_key
            AND s.team = g.team
            AND s.tick < g.tick
    )
    WHERE rn = 1
),
-- last score update before the next goal
score_after AS (
    SELECT replay_key, team, goal_tick, points, upd_tick
    FROM (
        SELECT g.replay_key, g.team, g.tick AS goal_tick,
            s.points, s.tick AS upd_tick,
            row_number() OVER (
                PARTITION BY g.replay_key, g.team, g.tick
                ORDER BY s.tick DESC, s.rowid DESC
            ) AS rn
        FROM goal_spans g
        JOIN scores s
            ON s.replay_key = g.replay_key
            AND s.team = g.team
            AND s.tick >= g.tick
            AND s.tick < g.window_end
    )
    WHERE rn = 1
),
-- for goals with rows in score_after, we calculate the value of the goal
-- as the value of the last score update minus the last reported score
-- for that team, minus the number of goals since that last score update
extra_points AS (
    SELECT g.replay_key, g.team, g.tick,
        after.points - coalesce(before.points, 0) -
            (SELECT count(*)
             FROM goals h
             WHERE h.replay_key = g.replay_key
               AND h.team = g.team
               AND h.tick > coalesce(before.upd_tick, -1)
               AND h.tick < g.tick) AS points
    FROM goal_spans g
    JOIN score_after after
        ON after.replay_key = g.replay_key
        AND after.team = g.team
        AND after.goal_tick = g.tick
    LEFT JOIN score_before before
        ON before.replay_key = g.replay_key
        AND before.team = g.team
        AND before.goal_tick = g.tick
)
SELECT g.replay_key, g.player_key, g.tick, g.team,
    coalesce(x.points, 1) AS points
FROM goal_spans g
LEFT JOIN extra_points x
    ON x.replay_key = g.replay_key
    AND x.team = g.team
    AND x.tick = g.tick;

COMMIT;
