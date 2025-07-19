WITH vapor_kills AS (
    SELECT
        ladder_games.replay_key AS replay_key,
        killing_player.vapor AS who_killed,
        dying_player.vapor AS who_died
    FROM ladder_games
    JOIN kills USING (replay_key)
    LEFT JOIN players killing_player ON
        killing_player.replay_key = kills.replay_key AND
        killing_player.player_key = kills.who_killed
    JOIN players dying_player ON
        dying_player.replay_key = kills.replay_key AND
        dying_player.player_key = kills.who_died
),
last_nicks AS (
    SELECT
        vapor,
        LAST_VALUE(nick) OVER (PARTITION BY vapor ORDER BY started_at) AS nick
    FROM replays
    NATURAL JOIN players
    GROUP BY vapor
),
kills_by_vapor AS (
    SELECT who_killed AS vapor, COUNT() as kills
    FROM vapor_kills
    GROUP BY who_killed
),
deaths_by_vapor AS (
    SELECT who_died AS vapor, COUNT() as deaths
    FROM vapor_kills
    GROUP BY who_died
)
SELECT nick, kills, deaths
FROM kills_by_vapor
JOIN deaths_by_vapor USING (vapor)
JOIN last_nicks USING (vapor)
ORDER BY kills DESC;
