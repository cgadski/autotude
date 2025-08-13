DROP TABLE IF EXISTS used_planes;
CREATE TABLE used_planes (
    replay_key INTEGER REFERENCES replays (replay_key),
    player_key INTEGER,
    handle_key INTEGER REFERENCES handles (handle_key),
    plane INTEGER,
    PRIMARY KEY (replay_key, player_key)
);

CREATE INDEX used_planes_handle_key ON used_planes (handle_key);
CREATE INDEX used_planes_plane ON used_planes (plane);

INSERT INTO used_planes
WITH plane_usage AS (
    SELECT
        spawns.replay_key,
        spawns.player_key,
        handles.handle_key,
        spawns.plane,
        sum(spawns.end_tick - spawns.start_tick) AS ticks_used,
        row_number() OVER (
            PARTITION BY spawns.replay_key, spawns.player_key
            ORDER BY sum(spawns.end_tick - spawns.start_tick) DESC
        ) AS usage_rank
    FROM ladder_games
    NATURAL JOIN spawns
    NATURAL JOIN players
    NATURAL JOIN handles
    WHERE players.team > 2
      AND spawns.plane IS NOT NULL
    GROUP BY spawns.replay_key, spawns.player_key, handles.handle_key, spawns.plane
)
SELECT
    replay_key,
    player_key,
    handle_key,
    plane
FROM plane_usage
WHERE usage_rank = 1;
