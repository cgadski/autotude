SELECT
    handle, plane, start_tick, end_tick, time_alive, time_with_ball
FROM players_wide
NATURAL JOIN replays
NATURAL JOIN handles
WHERE stem = 'a153d96f-b639-44e4-93d3-4758ee694a9e'
ORDER BY start_tick

-- SELECT handle, start_tick, end_tick
-- FROM possession
-- NATURAL JOIN player_key_handle
-- NATURAL JOIN handles
-- NATURAL JOIN replays
-- WHERE stem = 'a153d96f-b639-44e4-93d3-4758ee694a9e'
-- ORDER BY start_tick
