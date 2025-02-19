CREATE TABLE IF NOT EXISTS replays (
    "replay_key" INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "stem" VARCHAR,
    "map" VARCHAR,
    "server_name" VARCHAR,
    "ticks" INTEGER,
    "time" TIMESTAMP WITH TIME ZONE,
    "errored" BOOLEAN
);

CREATE INDEX IF NOT EXISTS idx_replays_step ON replays (stem);

CREATE INDEX IF NOT EXISTS idx_replays_map ON replays (map);

CREATE INDEX IF NOT EXISTS idx_replays_time ON replays (time);

-- a row in this table means a certain player was in a certain game
CREATE TABLE IF NOT EXISTS players (
    "player_key" INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    "replay_key" INTEGER REFERENCES replays (replay_key),
    "nick" VARCHAR,
    "vapor" VARCHAR,
    "level" INTEGER,
    "ace" INTEGER,
    "ticks_alive" INTEGER,
    "team" INTEGER
);

CREATE INDEX IF NOT EXISTS idx_players_nick ON players (nick);

CREATE INDEX IF NOT EXISTS idx_players_vapor ON players (vapor);

-- CREATE TABLE IF NOT EXISTS kills (
--     tick INTEGER NOT NULL,
--     replay_key INTEGER REFERENCES replays (replay_key),
--     who_killed INTEGER,
--     who_died INTEGER NOT NULL,
--     PRIMARY KEY (replay, tick, who_died)
-- );
-- CREATE INDEX IF NOT EXISTS kills_who_killed ON kills (replay, who_killed);
-- CREATE TABLE IF NOT EXISTS goals (
--     replay_key INTEGER REFERENCES replays (replay_key),
--     who_scored INTEGER
-- );
-- CREATE INDEX IF NOT EXISTS idx_goals_replay ON goals (replay);
-- CREATE INDEX IF NOT EXISTS idx_goals_who ON goals (who_scored);
-- CREATE TABLE IF NOT EXISTS chat (
--     replay_key INTEGER REFERENCES replays (replay_key),
--     tick INTEGER,
--     player INTEGER,
--     message TEXT,
--     PRIMARY KEY (replay, player, tick, message)
-- );
