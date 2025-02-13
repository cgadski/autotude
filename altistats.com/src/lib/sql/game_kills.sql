WITH player_names AS (
    SELECT 
        p.key::INTEGER as player_key,
        p.nick,
        p.team,
        p.replay_key
    FROM players p
    WHERE p.replay_key = CAST($1 AS INTEGER)
    AND p.team IN (3, 4)  -- Only include team players
)
SELECT 
    killer.nick as killer_name,
    killer.team as killer_team,
    victim.nick as victim_name,
    victim.team as victim_team,
    COUNT(*)::INTEGER as kill_count
FROM kills k
JOIN player_names killer ON k.who_killed = killer.player_key
JOIN player_names victim ON k.who_died = victim.player_key
WHERE k.replay = CAST($1 AS INTEGER)
AND killer.team != victim.team  -- Only include kills between teams
GROUP BY killer.nick, killer.team, victim.nick, victim.team
ORDER BY killer.team, killer.nick, victim.team, victim.nick;
