DROP TABLE IF EXISTS goals_valued;
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
SELECT g.replay_key, g.player_key, g.tick, g.team,
    CASE WHEN s.points IS NULL THEN 1 ELSE 2 END AS points
FROM goals g
LEFT JOIN scores s
    ON g.replay_key = s.replay_key AND g.tick = s.tick;
