SELECT replay_id, time, map, path,
    JSON_GROUP_ARRAY(JSON_ARRAY(name, team)) AS players
FROM replays NATURAL JOIN players 
WHERE map != 'lobby_4ball'
GROUP BY replay_id 
HAVING SUM(name = 'XX2') > 0 
    AND SUM(name LIKE 'Bot %') = 0
ORDER BY time DESC;
