BEGIN;

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
    handle_key,
    time_bin,
    plane,
    sum(time_alive) AS time_alive
FROM players_wide
GROUP BY handle_key, time_bin, plane;

COMMIT;
