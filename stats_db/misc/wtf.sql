SELECT time_bin, handle, stat, repr
FROM player_stats
NATURAL JOIN stats
NATURAL JOIN handles
WHERE query_name = 'p_death_rate'
AND plane = 1
-- AND time_bin is not null
-- AND NOT hidden
