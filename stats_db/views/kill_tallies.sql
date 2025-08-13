DROP TABLE IF EXISTS kill_tallies;
CREATE TABLE kill_tallies (
    replay_key REFERENCES replays (replay_key),
    player_key,
    handle_key REFERENCES handles (handle_key),
    kills,
    deaths,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX kill_tallies_handle_key ON kill_tallies (handle_key);

INSERT INTO kill_tallies
SELECT
    replay_key,
    player_key,
    handle_key,
    count() FILTER (WHERE who_killed = player_key) AS kills,
    count() FILTER (WHERE who_died = player_key) AS deaths
FROM replays
NATURAL JOIN players
NATURAL JOIN handles
NATURAL JOIN kills
GROUP BY replay_key, player_key, handle_key;
