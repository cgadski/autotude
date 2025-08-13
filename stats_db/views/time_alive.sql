DROP TABLE IF EXISTS time_alive;

CREATE TABLE time_alive (
    handle_key PRIMARY KEY,
    time_alive
);

INSERT INTO time_alive
SELECT handle, cast(sum(ticks_alive) AS real) AS time_alive
FROM ladder_games
NATURAL JOIN player_handles
GROUP BY handle;
