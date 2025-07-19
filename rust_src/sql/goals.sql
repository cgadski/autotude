SELECT COUNT(*) as total_goals FROM goals;
SELECT r.stem, p.nick, g.tick, g.team FROM goals g JOIN replays r ON g.replay_key = r.replay_key LEFT JOIN players p ON g.replay_key = p.replay_key AND g.player_key = p.player_key LIMIT 20;
