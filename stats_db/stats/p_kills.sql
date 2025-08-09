-- Lifetime kills
SELECT
    who_killed AS name,
    count(*) AS stat
FROM named_kills
GROUP BY who_killed
ORDER BY stat DESC;
