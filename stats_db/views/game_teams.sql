DROP TABLE IF EXISTS game_teams;
CREATE TABLE game_teams AS
WITH team_players AS (
    SELECT
        replay_key,
        team,
        json_group_array(
            json_object(
                'nick', nick,
                'vapor', vapor
            )
        ) AS players_json
    FROM ladder_games
    NATURAL JOIN players
    WHERE team IN (2, 3, 4)
    GROUP BY replay_key, team
),
teams_aggregated AS (
    SELECT
        replay_key,
        json_group_object(team, json(players_json)) AS teams
    FROM team_players
    GROUP BY replay_key
)
SELECT
    r.replay_key,
    datetime(r.started_at, 'unixepoch') AS started_at,
    r.map,
    r.stem,
    r.duration,
    coalesce(t.teams, '{}') AS teams
FROM ladder_games lg
JOIN replays r USING (replay_key)
LEFT JOIN teams_aggregated t USING (replay_key)
LIMIT 10;
