-- Teamkills
WITH tbl AS (
    SELECT
        handle_key,
        time_bin,
        plane,
        sum(team_kills) as tks,
        sum(time_alive) / (30 * 60 * 60) as hours
    FROM players_wide
    GROUP BY handle_key, time_bin, plane
)

-- handle
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    sum(tks) / sum(hours) AS stat,
    printf('%.3f / hour', sum(tks) / sum(hours)) || ' | '
    || sum(tks) || '#R in '
    || sum(30 * 60 * 60 * hours) || 'dc' AS repr,
    sum(hours) < 20 OR sum(tks) = 0 AS hidden
FROM tbl
GROUP BY handle_key

UNION ALL

-- handle, plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    sum(tks) / sum(hours) AS stat,
    printf('%.3f / hour', sum(tks) / sum(hours)) || ' | '
    || sum(tks) || '#R in '
    || sum(30 * 60 * 60 * hours) || 'dc' AS repr,
    sum(tks) = 0 AS hidden
FROM tbl
GROUP BY handle_key, plane

UNION ALL

-- handle, time
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    sum(tks) / sum(hours) AS stat,
    printf('%.3f / hour', sum(tks) / sum(hours)) || ' | '
    || sum(tks) || '#R in '
    || sum(30 * 60 * 60 * hours) || 'dc' AS repr,
    sum(tks) = 0 AS hidden
FROM tbl
GROUP BY handle_key, time_bin

UNION ALL

-- handle, time, plane
SELECT
    handle_key,
    time_bin,
    plane,
    sum(tks) / sum(hours) AS stat,
    printf('%.3f / hour', sum(tks) / sum(hours)) || ' | '
    || sum(tks) || '#R in '
    || sum(30 * 60 * 60 * hours) || 'dc' AS repr,
    sum(tks) = 0 AS hidden
FROM tbl
GROUP BY handle_key, plane, time_bin
