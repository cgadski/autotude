DROP TABLE IF EXISTS players_short;

CREATE TABLE players_short (
    replay_key,
    handle_key,
    time_bin,
    plane,
    team,
    won,
    PRIMARY KEY (replay_key, handle_key)
);

CREATE INDEX idx_players_short_handle ON players_short (handle_key, time_bin);

INSERT INTO players_short
WITH plane_usage AS (
  SELECT *, sum(time_alive) as total_time_alive
  FROM players_wide
  GROUP BY handle_key, replay_key, plane
),
plane_usage_ranked AS (
  SELECT *,
    row_number() OVER (
      PARTITION BY handle_key, replay_key
      ORDER BY total_time_alive DESC
    ) as r
  FROM plane_usage
)
SELECT
    replay_key,
    handle_key,
    rw.time_bin,
    plane,
    team,
    rw.winner = team AS won
FROM plane_usage_ranked
JOIN replays_wide rw USING (replay_key)
WHERE r = 1;
