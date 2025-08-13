-- Win rate
-- percentage
WITH
tbl AS (
    SELECT
        pw.handle_key,
        pw.time_bin,
        pw.plane,
        SUM(CASE WHEN games_wide.winner = pw.team THEN 1 ELSE 0 END) AS wins,
        COUNT(*) AS games
    FROM players_wide pw
    JOIN games_wide USING (replay_key)
    GROUP BY pw.handle_key, pw.time_bin, pw.plane
)
-- Specific month and plane
SELECT
    handle_key,
    time_bin,
    plane,
    CAST(wins AS REAL) / games AS stat
FROM tbl
WHERE games > 0

UNION ALL

-- All-time for specific plane
SELECT
    handle_key,
    NULL AS time_bin,
    plane,
    CAST(sum(wins) AS REAL) / sum(games) AS stat
FROM tbl
GROUP BY handle_key, plane
HAVING sum(games) > 0

UNION ALL

-- Specific month across all planes
SELECT
    handle_key,
    time_bin,
    NULL AS plane,
    CAST(sum(wins) AS REAL) / sum(games) AS stat
FROM tbl
GROUP BY handle_key, time_bin
HAVING sum(games) > 0

UNION ALL

-- All-time across all planes
SELECT
    handle_key,
    NULL AS time_bin,
    NULL AS plane,
    CAST(sum(wins) AS REAL) / sum(games) AS stat
FROM tbl
GROUP BY handle_key
HAVING sum(games) > 0
ORDER BY stat DESC
