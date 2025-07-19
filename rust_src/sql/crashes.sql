SELECT
    COUNT(*) as total_crashes,
    p.nick as nick
FROM kills k
JOIN players p ON k.replay_key = p.replay_key AND k.who_died = p.player_key
WHERE k.who_killed IS NULL
GROUP BY p.vapor
ORDER BY total_crashes DESC
LIMIT 50;
