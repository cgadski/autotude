-- Total messages
SELECT count()
FROM messages
WHERE player_key IS NOT NULL
