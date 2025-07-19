SELECT COUNT(*) as total_messages FROM messages;
SELECT r.stem, p.nick, m.chat_message FROM messages m JOIN replays r ON m.replay_key = r.replay_key LEFT JOIN players p ON m.replay_key = p.replay_key AND m.player_key = p.player_key LIMIT 20;
