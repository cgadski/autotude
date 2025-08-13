-- Time alive per kill
-- duration_fine reverse
WITH
tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        time_alive,
        kills
    FROM players_wide
    WHERE kills > 0
)
-- Specific month and plane
SELECT
    handle_key,
    time_bin,
    plane,
    time_alive / kills AS stat
FROM tbl
WHERE kills > 0

UNION ALL

-- All-time for specific plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_alive) / sum(kills) AS stat
FROM tbl
GROUP BY handle_key, plane
HAVING sum(kills) > 0

UNION ALL

-- Specific month across all planes
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_alive) / sum(kills) AS stat
FROM tbl
GROUP BY handle_key, time_bin
HAVING sum(kills) > 0

UNION ALL

-- All-time across all planes
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_alive) / sum(kills) AS stat
FROM tbl
GROUP BY handle_key
HAVING sum(kills) > 0
ORDER BY stat
