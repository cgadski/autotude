-- Time by player, month, and plane
-- duration
WITH
tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        time_alive AS stat
    FROM players_wide
)
-- Specific month and plane
SELECT
    handle_key,
    time_bin,
    plane,
    stat
FROM tbl

UNION ALL

-- All-time for specific plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(stat) AS stat
FROM tbl
GROUP BY handle_key, plane

UNION ALL

-- Specific month across all planes
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(stat) AS stat
FROM tbl
GROUP BY handle_key, time_bin

UNION ALL

-- All-time across all planes
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(stat) AS stat
FROM tbl
GROUP BY handle_key
ORDER BY stat DESC
