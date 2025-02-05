SELECT
    datetime,
    floor(tick/30) AS t,
    nick,
    message
FROM chat c
JOIN players p ON (p.key = c.player)
JOIN replays r ON (r.key = p.replay_key)
ORDER BY datetime, tick;
