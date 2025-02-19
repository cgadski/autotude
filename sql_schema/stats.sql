CREATE TABLE IF NOT EXISTS damage (
    tick INTEGER,
    replay INTEGER,
    who_gave INTEGER,
    who_received INTEGER,
    amount INTEGER
);

CREATE INDEX IF NOT EXISTS damage_replay ON damage (replay);

CREATE TABLE IF NOT EXISTS ball (
    tick INTEGER,
    replay INTEGER,
    player INTEGER,
    x INTEGER,
    y INTEGER,
);

CREATE INDEX IF NOT EXISTS ball_replay ON ball (replay);

CREATE INDEX IF NOT EXISTS ball_player ON ball (player);
