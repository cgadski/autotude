SELECT COUNT(*) as total_players FROM players;
SELECT p.nick, p.vapor, r.stem FROM players p JOIN replays r ON p.replay_key = r.replay_key LIMIT 20;
