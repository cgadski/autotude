CREATE SEQUENCE IF NOT EXISTS replay_keys;

CREATE TABLE IF NOT EXISTS replays (
    key INTEGER PRIMARY KEY,
    path VARCHAR,
    map VARCHAR,
    ticks INTEGER,
    datetime TIMESTAMP,
    dumped BOOLEAN DEFAULT FALSE,
);

CREATE INDEX IF NOT EXISTS idx_replays_path ON replays(path);
CREATE INDEX IF NOT EXISTS idx_replays_map ON replays(map);
CREATE INDEX IF NOT EXISTS idx_replays_datetime ON replays(datetime);

CREATE SEQUENCE IF NOT EXISTS player_keys START 1;

-- a row in this table means a certain player was in a certain game
CREATE TABLE IF NOT EXISTS players (
    key INTEGER PRIMARY KEY,
    replay_key INTEGER,
    nick VARCHAR,
    vapor VARCHAR,
    level INTEGER,
    ace INTEGER,
    ticks_alive INTEGER
);

CREATE INDEX IF NOT EXISTS idx_in_game_replay ON players(replay_key);
CREATE INDEX IF NOT EXISTS idx_in_game_nick ON players(nick);
CREATE INDEX IF NOT EXISTS idx_in_game_vapor ON players(vapor);

CREATE TABLE IF NOT EXISTS states (
    player INTEGER,
    tick INTEGER,
    plane INTEGER,
    team INTEGER,
    x INTEGER,
    y INTEGER,
    dir INTEGER,
    health INTEGER,
    ammo INTEGER,
    throttle INTEGER,
    bars INTEGER
);

CREATE INDEX IF NOT EXISTS idx_states_player ON states(player, tick);
CREATE INDEX IF NOT EXISTS idx_states_tick ON states(tick, player);

CREATE TABLE IF NOT EXISTS kills (
    tick INTEGER,
    replay INTEGER,
    who_killed INTEGER,
    who_died INTEGER,
    PRIMARY KEY (replay, tick, who_died)
);

CREATE INDEX IF NOT EXISTS kills_who_killed ON kills(replay, who_killed);

CREATE TABLE IF NOT EXISTS damage (
    tick INTEGER,
    replay INTEGER,
    who_gave INTEGER,
    who_received INTEGER,
    amount INTEGER
);

CREATE INDEX IF NOT EXISTS damage_replay ON damage(replay);

CREATE TABLE IF NOT EXISTS goals (
    replay INTEGER,
    who_scored INTEGER
);

CREATE INDEX IF NOT EXISTS idx_goals_replay ON goals(replay);
CREATE INDEX IF NOT EXISTS idx_goals_who ON goals(who_scored);

CREATE TABLE IF NOT EXISTS chat (
    replay INTEGER,
    tick INTEGER,
    player INTEGER,
    message TEXT,
    PRIMARY KEY (replay, player, tick, message)
);
