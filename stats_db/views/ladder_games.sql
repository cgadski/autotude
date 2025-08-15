DROP TABLE IF EXISTS ladder_games;
CREATE TABLE ladder_games (
    replay_key INTEGER PRIMARY KEY REFERENCES replays (replay_key)
);

INSERT INTO ladder_games
SELECT a.replay_key
FROM replays_wide a
LEFT JOIN replays_wide next ON (next.replay_key = a.next_key)
JOIN replays_wide prev ON (prev.replay_key = a.prev_key)
WHERE
-- conditions for a game to be a ladder game:
(prev.start_messages > 0 OR a.restart_messages > 0) -- started
AND coalesce(next.stop_messages, 0) < 1 -- not stopped
AND next.restart_messages < 1 -- not restarted
AND a.n_left = 4 -- 4 total vapors on left team
AND a.n_right = 4 -- 4 total vapors on right team
AND a.n_goals >= 0; -- at least one goal scored
