CREATE TABLE IF NOT EXISTS replays_raw (
    "replay_key" INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "stem" VARCHAR,
    "map" VARCHAR,
    "server" VARCHAR,
    "duration" INTEGER,
    "started_at" TIMESTAMP WITH TIME ZONE,
    "completed" BOOLEAN,
    "status" VARCHAR
);

CREATE INDEX IF NOT EXISTS idx_replays_stem ON replays_raw (stem);
CREATE INDEX IF NOT EXISTS idx_replays_map ON replays_raw (map);
CREATE INDEX IF NOT EXISTS idx_replays_started_at ON replays_raw (started_at);

-- a row in this table means a certain player was in a certain game
CREATE TABLE IF NOT EXISTS players (
    "replay_key" INTEGER REFERENCES replays_raw (replay_key),
    "player_key" INTEGER,
    "nick" VARCHAR,
    "vapor" VARCHAR,
    "level" INTEGER,
    "ace" INTEGER,
    "ticks_alive" INTEGER,
    "team" INTEGER,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX IF NOT EXISTS idx_players_nick ON players (nick);

CREATE INDEX IF NOT EXISTS idx_players_vapor ON players (vapor);
