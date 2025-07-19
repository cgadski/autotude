SELECT COUNT(*) as total_kills FROM kills;
SELECT r.stem, pk.nick as killer, pd.nick as victim, k.tick
FROM kills k
JOIN replays r ON k.replay_key = r.replay_key
LEFT JOIN players pk ON k.replay_key = pk.replay_key AND k.who_killed = pk.player_key
LEFT JOIN players pd ON k.replay_key = pd.replay_key AND k.who_died = pd.player_key
ORDER BY k.tick
LIMIT 20;
