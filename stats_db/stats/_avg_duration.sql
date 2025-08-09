-- Average game duration
SELECT
    avg(CAST(duration AS REAL) / (30 * 60)) AS stat
FROM ladder_games
NATURAL JOIN replays;
