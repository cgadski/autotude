-- Time per death
-- duration_fine
WITH
tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        time_alive,
        deaths
    FROM players_wide
    WHERE deaths > 0
)
-- Specific month and plane
SELECT
    handle_key,
    time_bin,
    plane,
    time_alive / deaths AS stat
FROM tbl
WHERE deaths > 0

UNION ALL

-- All-time for specific plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(time_alive) / sum(deaths) AS stat
FROM tbl
GROUP BY handle_key, plane
HAVING sum(deaths) > 0

UNION ALL

-- Specific month across all planes
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(time_alive) / sum(deaths) AS stat
FROM tbl
GROUP BY handle_key, time_bin
HAVING sum(deaths) > 0

UNION ALL

-- All-time across all planes
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(time_alive) / sum(deaths) AS stat
FROM tbl
GROUP BY handle_key
HAVING sum(deaths) > 0
ORDER BY stat
