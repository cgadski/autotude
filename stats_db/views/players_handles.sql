DROP TABLE IF EXISTS players_handles;
CREATE TABLE players_handles (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    handle_key INTEGER REFERENCES handles (handle_key),
    team,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX players_handles_handle ON players_handles (handle_key);

INSERT INTO players_handles
SELECT replay_key, player_key, handle_key, team
FROM players
JOIN handles USING (vapor);
