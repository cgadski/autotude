WITH
    player_counts AS (
        SELECT
            r.key,
            COUNT() AS n_players
        FROM replays r
        JOIN players p on p.replay_key = r.key
    ),
    player_teams AS (
        SELECT
            r.key,
            p.nick,
            SUM(p.ticks_alive) AS ticks_alive,
            ANY_VALUE(p.team) AS team
        FROM replays r
        JOIN players p ON p.replay_key = r.key
        GROUP BY r.key, p.nick
        HAVING ANY_VALUE(p.team) > 2
    ),
    teams AS (
        SELECT r.key AS key,
            json_group_array(
                json_object(
                    'nick', pt.nick,
                    'team', pt.team,
                    'ticks_alive', pt.ticks_alive
                )
            ) as players,
        FROM replays r
        LEFT JOIN player_teams pt USING (key)
        GROUP BY r.key
    ),
    last_goal AS (
        SELECT replay AS key, LAST(team) AS last_team
        FROM goals g
        JOIN players p ON (g.who_scored = p.key)
        GROUP BY replay
    )

SELECT replays.*, teams.*,
    ticks / 30 / 60 AS minutes,
    last_goal.last_team AS last_goal_team
FROM replays
JOIN teams USING (key)
JOIN last_goal USING (key)
ORDER BY datetime DESC
LIMIT 20;
