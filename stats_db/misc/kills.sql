WITH
player_kills AS (
    SELECT who_killed AS name, COUNT() AS n_kills
    FROM named_kills
    WHERE who_killed IS NOT NULL
    GROUP BY who_killed
),
player_deaths AS (
    SELECT who_died AS name, COUNT() AS n_deaths
    FROM named_kills
    GROUP BY who_died
)
SELECT name, n_kills, n_deaths, printf('%.2f', CAST(n_kills AS REAL) / n_deaths) AS kd
FROM (SELECT DISTINCT name FROM names)
NATURAL JOIN player_kills
NATURAL JOIN player_deaths
ORDER BY kd DESC;
