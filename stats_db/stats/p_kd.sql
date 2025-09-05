-- Kills/deaths
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        cast(sum(kills) AS REAL) AS kills,
        cast(sum(deaths) AS REAL) AS deaths
    FROM players_wide
    GROUP BY handle_key, time_bin, plane
)
-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(kills) / sum(deaths) AS stat,
    format('%.2f', sum(kills) / sum(deaths)) ||
    ' | ' || cast(sum(kills) AS int) || ' : ' || cast(sum(deaths) AS int)
    AS repr,
    sum(kills) < 1000 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(kills) / sum(deaths) AS stat,
    format('%.2f', sum(kills) / sum(deaths)) ||
    ' | ' || cast(sum(kills) AS int) || '#G : ' || cast(sum(deaths) AS int)
    || '#R'
    AS repr,
    sum(kills) < 250 AS hidden
FROM tbl GROUP BY handle_key, time_bin

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(kills) / sum(deaths) AS stat,
    format('%.2f', sum(kills) / sum(deaths)) ||
    ' | ' || cast(sum(kills) AS int) || ' : ' || cast(sum(deaths) AS int)
    AS repr,
    sum(kills) < 250 AS hidden
FROM tbl GROUP BY handle_key, plane

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(kills) / sum(deaths) AS stat,
    format('%.2f', sum(kills) / sum(deaths)) ||
    ' | ' || cast(sum(kills) AS int) || ' : ' || cast(sum(deaths) AS int)
    AS repr,
    false AS hidden
FROM tbl
