SELECT
    count() FILTER (WHERE team = 3) AS blue_kills,
    count() FILTER (WHERE team = 4) AS red_kills
FROM kills
NATURAL JOIN ladder_games
JOIN players ON
    players.replay_key = kills.replay_key AND
    players.player_key = kills.who_killed;
