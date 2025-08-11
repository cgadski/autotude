DROP TABLE IF EXISTS last_played;
CREATE TABLE last_played (
    handle TEXT PRIMARY KEY,
    started_at
);

INSERT INTO last_played
SELECT handle, max(started_at)
FROM ladder_games
NATURAL JOIN replays
NATURAL JOIN players
NATURAL JOIN handles
WHERE team > 2
GROUP BY handle;
