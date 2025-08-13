DROP TABLE IF EXISTS last_played;
CREATE TABLE last_played (
    handle_key INTEGER PRIMARY KEY REFERENCES handles (handle_key),
    started_at
);

INSERT INTO last_played
SELECT handle_key, max(started_at)
FROM ladder_games
NATURAL JOIN replays
NATURAL JOIN players_handles
WHERE team > 2
GROUP BY handle_key;
