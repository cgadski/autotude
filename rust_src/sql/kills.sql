WITH named_kills AS (
    SELECT
        ladder_games.replay_key AS replay_key,
        kills.who_killed AS killed_key,
        killing_player.name AS who_killed,
        dying_player.name AS who_died
    FROM ladder_games
    JOIN kills USING (replay_key)
    LEFT JOIN players p0 ON
        p0.replay_key = kills.replay_key AND
        p0.player_key = kills.who_killed
    LEFT JOIN names killing_player ON
        killing_player.vapor = p0.vapor
    JOIN players p1 ON
        p1.replay_key = kills.replay_key AND
        p1.player_key = kills.who_died
    JOIN names dying_player ON
        dying_player.vapor = p1.vapor
    WHERE kills.who_killed IS NOT NULL
)
SELECT
    stem,
    replay_key,
    COUNT() FILTER (WHERE who_killed = 'xx2') AS kills,
    COUNT() FILTER (WHERE who_died = 'xx2') AS deaths
FROM named_kills
NATURAL JOIN replays
GROUP BY replay_key;
