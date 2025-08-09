CREATE TABLE replays (
    replay_key INTEGER PRIMARY KEY,
    stem TEXT,
    map TEXT,
    server TEXT,
    duration INTEGER,
    started_at INTEGER
);

CREATE INDEX idx_replays_stem ON replays (stem);
CREATE INDEX idx_replays_map ON replays (map);
CREATE INDEX idx_replays_started_at ON replays (started_at);

CREATE TABLE errored (stem TEXT PRIMARY KEY);

CREATE TABLE players (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    nick TEXT,
    vapor TEXT,
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

CREATE TABLE kills (
    replay_key INTEGER REFERENCES replays (replay_key),
    who_killed INTEGER,
    who_died INTEGER,
    tick INTEGER,
    PRIMARY KEY (replay_key, who_killed, who_died, tick)
);

CREATE TABLE possession (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    start_tick INTEGER,
    end_tick INTEGER,
    PRIMARY KEY (replay_key, player_key, start_tick)
);

CREATE TABLE spawns (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    plane INTEGER,
    red_perk INTEGER,
    green_perk INTEGER,
    blue_perk INTEGER,
    start_tick INTEGER,
    end_tick INTEGER,
    PRIMARY KEY (replay_key, player_key, start_tick)
);
