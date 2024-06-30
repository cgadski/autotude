SELECT replay_id, time, map, path, ticks,
    JSON_GROUP_ARRAY(JSON_ARRAY(name, team)) AS players
FROM replays NATURAL JOIN players 
WHERE map LIKE '%race%'
GROUP BY replay_id 
-- HAVING SUM(name LIKE '%[test]%') > 0 
    -- AND SUM(name LIKE 'Bot %') = 0
ORDER BY time DESC;
