SELECT format('http://altistats.com/viewer/?f=%s.pb', stem), tick, p_killed.team, p_died.team, row_number() OVER (ORDER BY tick)
FROM kills
NATURAL JOIN replays
JOIN players p_died ON (
    kills.replay_key = p_died.replay_key AND
    kills.who_died = p_died.player_key
)
JOIN players p_killed ON (
    kills.replay_key = p_killed.replay_key AND
    kills.who_killed = p_killed.player_key
)
JOIN player_key_handle ph_killed ON (
    kills.replay_key = ph_killed.replay_key AND
    kills.who_killed= ph_killed.player_key
)
NATURAL JOIN handles
WHERE stem = 'fde073a2-65d1-4caf-baea-9348a14f3785'
AND handle = 'jose'
AND p_killed.team = p_died.team;
