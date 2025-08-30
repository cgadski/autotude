SELECT stem, primary_planes.*
FROM primary_planes
NATURAL JOIN replays
WHERE handle_key = 45
AND time_bin = 7
AND plane = 4;
