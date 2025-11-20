SELECT
    handle,
    format('%.3f', (30 * 60 * 60) * sum(team_kills) / sum(time_alive)) AS tks_per_hour,
    sum(team_kills) AS total_tks,
    sum(time_alive) / (30 * 60 * 30) AS hours
FROM players_wide
NATURAL JOIN handles
GROUP BY handle
ORDER BY hours DESC
LIMIT 50;
