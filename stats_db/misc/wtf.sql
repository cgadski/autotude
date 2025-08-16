SELECT replays.stem, map, started_at, teams
FROM replays
JOIN game_teams USING (replay_key)
WHERE stem = 'e49c1df7-d9e5-4eff-9c04-9590660e7e6e'
