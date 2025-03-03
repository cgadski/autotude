CREATE TABLE IF NOT EXISTS kills (
    tick INTEGER NOT NULL,
    replay_key INTEGER REFERENCES replays (replay_key),
    who_killed INTEGER,
    who_died INTEGER NOT NULL,
    PRIMARY KEY (replay, tick, who_died)
);

CREATE INDEX IF NOT EXISTS kills_who_killed ON kills (replay, who_killed);

CREATE TABLE IF NOT EXISTS goals (
    replay_key INTEGER REFERENCES replays (replay_key),
    who_scored INTEGER
);

CREATE INDEX IF NOT EXISTS idx_goals_replay ON goals (replay);
CREATE INDEX IF NOT EXISTS idx_goals_who ON goals (who_scored);

CREATE TABLE IF NOT EXISTS chat (
    replay_key INTEGER REFERENCES replays (replay_key),
    tick INTEGER,
    player INTEGER,
    message TEXT,
    PRIMARY KEY (replay, player, tick, message)
);

CREATE TABLE IF NOT EXISTS damage (
    replay_key INTEGER,
    tick INTEGER,
    who_gave INTEGER,
    who_received INTEGER,
    amount INTEGER
);

CREATE INDEX IF NOT EXISTS idx_damage_replay ON damage (replay);

CREATE TABLE IF NOT EXISTS ball (
    tick INTEGER,
    replay INTEGER,
    player INTEGER,
    x INTEGER,
    y INTEGER,
);

CREATE INDEX IF NOT EXISTS ball_replay ON ball (replay);

CREATE INDEX IF NOT EXISTS ball_player ON ball (player);
