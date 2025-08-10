DROP VIEW IF EXISTS other_nicks;
CREATE VIEW other_nicks AS
SELECT
    a.vapor,
    a.handle,
    json_group_array(DISTINCT players.nick) AS nicks
FROM handles a
JOIN handles b ON (a.name = b.name)
JOIN players ON (players.vapor = b.vapor)
GROUP BY a.vapor, a.name;
