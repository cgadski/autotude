DROP TABLE IF EXISTS time_alive;

CREATE TABLE time_alive (
    handle_key,
    time_bin,
    plane,
    time_alive,
    PRIMARY KEY (handle_key, time_bin, plane)
);

INSERT INTO time_alive
SELECT
    handles.handle_key,
    time_bins.time_bin,
    spawns.plane,
    cast(sum(spawns.end_tick - spawns.start_tick) AS real) AS time_alive
FROM ladder_games
NATURAL JOIN players
NATURAL JOIN spawns
NATURAL JOIN handles
NATURAL JOIN time_bins
WHERE spawns.plane IS NOT NULL
GROUP BY handles.handle_key, time_bins.time_bin, spawns.plane;
