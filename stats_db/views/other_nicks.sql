DROP TABLE IF EXISTS other_nicks;
CREATE TABLE other_nicks AS
SELECT
    a.vapor,
    a.handle,
    json_group_array(DISTINCT players.nick) AS nicks
FROM handles a
JOIN handles b ON (a.handle = b.handle)
JOIN players ON (players.vapor = b.vapor)
GROUP BY a.vapor, a.handle;
