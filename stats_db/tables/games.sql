BEGIN;

DROP TABLE IF EXISTS series;
CREATE TABLE series (
    series_key INTEGER PRIMARY KEY,
    series_name TEXT
);

INSERT INTO series
VALUES
    (0, '4v4 ladder'),
    -- 25/1/2026
    (1, 'Top Dog Bowl I'),
    -- 14/3/2026
    (2, 'Top Dog Bowl II');

DROP TABLE IF EXISTS games;
CREATE TABLE games (
    replay_key INTEGER PRIMARY KEY REFERENCES replays (replay_key),
    series_key INTEGER
);

--
-- ladder games
--
INSERT INTO games
SELECT a.replay_key, 0
FROM replays_wide a NATURAL JOIN replays
LEFT JOIN replays_wide next ON (next.replay_key = a.next_key)
JOIN replays_wide prev ON (prev.replay_key = a.prev_key)
WHERE
-- conditions for a game to be a ladder game:
server LIKE '%Ranked%'
AND (prev.start_messages > 0 OR a.restart_messages > 0) -- started
AND coalesce(next.stop_messages, 0) < 1 -- not stopped
AND coalesce(next.restart_messages, 0) < 1 -- not restarted
AND a.n_left = 4 -- 4 total vapors on left team
AND a.n_right = 4 -- 4 total vapors on right team
AND a.n_goals > 0; -- at least one goal scored

--
-- top dog bowl I on 25/1/2026
--
INSERT INTO games
SELECT replay_key, 1
FROM replays_wide NATURAL JOIN replays
WHERE server LIKE '%League%'
AND n_left >= 4 AND n_right >= 4 AND n_goals > 0
AND day_bin = '2026-01-25';

--
-- top dog bowl II on 14/3/2026
--
INSERT INTO games
SELECT replay_key, 2
FROM replays_wide NATURAL JOIN replays
WHERE server LIKE '%League%'
AND n_left >= 4 AND n_right >= 4 AND n_goals > 0
AND day_bin = '2026-03-14';

COMMIT;
