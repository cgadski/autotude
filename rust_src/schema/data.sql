CREATE TABLE replays (
    replay_key INTEGER PRIMARY KEY,
    stem VARCHAR,
    map VARCHAR,
    server VARCHAR,
    duration INTEGER,
    started_at INTEGER
);

CREATE INDEX idx_replays_stem ON replays (stem);
CREATE INDEX idx_replays_map ON replays (map);
CREATE INDEX idx_replays_started_at ON replays (started_at);

CREATE TABLE players (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    nick VARCHAR,
    vapor VARCHAR,
    level INTEGER,
    ticks_alive INTEGER,
    team INTEGER,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX idx_players_nick ON players (nick);
CREATE INDEX idx_players_vapor ON players (vapor);

CREATE TABLE messages (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    tick INTEGER,
    chat_team TEXT,
    chat_message TEXT
);

CREATE INDEX idx_messages_replay ON messages (replay_key);

CREATE TABLE goals (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    tick INTEGER,
    team INTEGER
);

CREATE INDEX idx_goals_replay ON goals (replay_key);
