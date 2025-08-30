DROP VIEW IF EXISTS primary_planes;
CREATE VIEW primary_planes AS
WITH plane_usage AS (
  SELECT *, sum(time_alive) as total_time_alive
  FROM players_wide pw
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
    handle_key,
    replay_key,
    time_bin,
    plane,
    team
FROM plane_usage_ranked
WHERE r = 1;
