SELECT 
    replay_id,
    time,
    map,
    path,
    JSON_GROUP_ARRAY(name) AS players
FROM replays NATURAL JOIN players 
WHERE path LIKE '%ball_4planepark%' 
GROUP BY replay_id 
HAVING SUM(name = 'sleepyduck') > 0 
ORDER BY time;
